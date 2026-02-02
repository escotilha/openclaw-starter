#!/bin/bash

echo "🏥 OpenClaw Health Check"
echo "========================"
echo ""

EXIT_CODE=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    EXIT_CODE=1
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Node.js
echo "📦 Verificando dependências..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    check_ok "Node.js instalado: $NODE_VERSION"
else
    check_fail "Node.js não encontrado. Instale: https://nodejs.org"
fi

# 2. OpenClaw CLI
if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    check_ok "OpenClaw instalado: $OPENCLAW_VERSION"
else
    check_fail "OpenClaw não encontrado. Instale: npm install -g openclaw"
fi

echo ""
echo "🗄️  Verificando PostgreSQL..."

# 3. PostgreSQL
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | cut -d' ' -f3)
    check_ok "PostgreSQL instalado: $PSQL_VERSION"
    
    # Verificar serviço rodando
    if psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw template1; then
        check_ok "PostgreSQL rodando"
    else
        check_fail "PostgreSQL não está rodando. Inicie: brew services start postgresql@16"
    fi
else
    check_fail "psql não encontrado. Instale PostgreSQL."
fi

# 4. Database openclaw_memory
if psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw openclaw_memory; then
    check_ok "Database openclaw_memory existe"
    
    # Verificar pgvector
    if psql openclaw_memory -tAc "SELECT 1 FROM pg_extension WHERE extname='vector';" 2>/dev/null | grep -q 1; then
        check_ok "Extensão pgvector habilitada"
    else
        check_fail "pgvector não habilitado. Execute: psql openclaw_memory -c 'CREATE EXTENSION vector;'"
    fi
    
    # Verificar tabela memories
    if psql openclaw_memory -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='memories';" 2>/dev/null | grep -q 1; then
        check_ok "Tabela memories existe"
        
        # Contar memórias
        MEMORY_COUNT=$(psql openclaw_memory -tAc "SELECT COUNT(*) FROM memories;" 2>/dev/null || echo "0")
        if [ "$MEMORY_COUNT" -gt 0 ]; then
            check_ok "Memórias armazenadas: $MEMORY_COUNT"
        else
            check_warn "Nenhuma memória armazenada ainda (esperado se primeira vez)"
        fi
    else
        check_fail "Tabela memories não existe. Execute: ./scripts/setup-postgres.sh"
    fi
else
    check_fail "Database openclaw_memory não existe. Execute: ./scripts/setup-postgres.sh"
fi

echo ""
echo "⚙️  Verificando configuração..."

# 5. Pasta ~/.openclaw
if [ -d ~/.openclaw ]; then
    check_ok "Pasta ~/.openclaw existe"
    
    # Verificar permissões
    PERMS=$(stat -f "%Lp" ~/.openclaw 2>/dev/null || stat -c "%a" ~/.openclaw 2>/dev/null)
    if [ "$PERMS" = "700" ]; then
        check_ok "Permissões corretas (700)"
    else
        check_warn "Permissões inseguras ($PERMS). Recomendado: chmod 700 ~/.openclaw"
    fi
else
    check_fail "Pasta ~/.openclaw não existe. Crie: mkdir -p ~/.openclaw"
fi

# 6. openclaw.json
if [ -f ~/.openclaw/openclaw.json ]; then
    check_ok "Arquivo openclaw.json existe"
    
    # Validar JSON
    if cat ~/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1; then
        check_ok "openclaw.json é JSON válido"
    else
        check_fail "openclaw.json tem erro de sintaxe"
    fi
else
    check_fail "openclaw.json não encontrado. Copie: cp templates/single-agent.json ~/.openclaw/openclaw.json"
fi

# 7. .env
if [ -f ~/.openclaw/.env ]; then
    check_ok "Arquivo .env existe"
    
    # Verificar keys obrigatórias
    if grep -q "OPENAI_API_KEY=" ~/.openclaw/.env; then
        if grep -q "OPENAI_API_KEY=sk-" ~/.openclaw/.env; then
            check_ok "OPENAI_API_KEY configurada"
        else
            check_warn "OPENAI_API_KEY parece placeholder"
        fi
    else
        check_fail "OPENAI_API_KEY não encontrada no .env"
    fi
    
    if grep -q "GATEWAY_AUTH_TOKEN=" ~/.openclaw/.env; then
        TOKEN=$(grep "GATEWAY_AUTH_TOKEN=" ~/.openclaw/.env | cut -d'=' -f2)
        if [ ${#TOKEN} -ge 32 ]; then
            check_ok "GATEWAY_AUTH_TOKEN configurado"
        else
            check_warn "GATEWAY_AUTH_TOKEN muito curto (mínimo 32 caracteres)"
        fi
    else
        check_warn "GATEWAY_AUTH_TOKEN não encontrado (opcional mas recomendado)"
    fi
else
    check_fail ".env não encontrado. Copie: cp templates/.env.example ~/.openclaw/.env"
fi

echo ""
echo "🚀 Verificando gateway..."

# 8. Gateway status
if openclaw gateway status &> /dev/null; then
    GATEWAY_STATUS=$(openclaw gateway status 2>&1)
    if echo "$GATEWAY_STATUS" | grep -q "running"; then
        check_ok "Gateway rodando"
        
        # Verificar porta
        PORT=$(grep -A 2 '"gateway"' ~/.openclaw/openclaw.json | grep '"port"' | grep -o '[0-9]\+')
        PORT=${PORT:-8080}
        
        if lsof -i :$PORT > /dev/null 2>&1; then
            check_ok "Porta $PORT aberta"
        else
            check_warn "Porta $PORT não está escutando"
        fi
        
        # Testar endpoint
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/api/status 2>/dev/null | grep -q "200\|401"; then
            check_ok "API respondendo"
        else
            check_warn "API não responde em http://localhost:$PORT"
        fi
    else
        check_warn "Gateway não está rodando. Inicie: openclaw gateway start"
    fi
else
    check_warn "Gateway não está rodando. Inicie: openclaw gateway start"
fi

# 9. Logs
if [ -f ~/.openclaw/logs/gateway.log ]; then
    check_ok "Arquivo de log existe"
    
    # Verificar erros recentes
    RECENT_ERRORS=$(tail -100 ~/.openclaw/logs/gateway.log 2>/dev/null | grep -i "error" | wc -l)
    if [ "$RECENT_ERRORS" -gt 0 ]; then
        check_warn "Encontrados $RECENT_ERRORS erros recentes nos logs"
    fi
else
    check_warn "Arquivo de log não encontrado (esperado se gateway nunca iniciou)"
fi

echo ""
echo "========================"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Tudo OK! OpenClaw está pronto.${NC}"
    echo ""
    echo "🎉 Próximos passos:"
    echo "   1. Iniciar gateway: openclaw gateway start"
    echo "   2. Acessar webchat: http://localhost:8080"
    echo "   3. Conectar canais: docs/CHANNELS.md"
else
    echo -e "${RED}❌ Problemas encontrados. Corrija os erros acima.${NC}"
    echo ""
    echo "📖 Guias:"
    echo "   - Instalação: docs/INSTALL.md"
    echo "   - PostgreSQL: docs/MEMORY.md"
    echo "   - Segurança: docs/SECURITY.md"
fi
echo ""

exit $EXIT_CODE
