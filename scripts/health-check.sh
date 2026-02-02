#!/bin/bash
# Script de Health Check para OpenClaw
# Verifica instalação, configuração e conectividade

echo "================================================"
echo "OpenClaw Health Check"
echo "================================================"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Função para verificação
check() {
    local name=$1
    local command=$2
    local expected=$3
    
    echo -n "Verificando $name... "
    
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_warn() {
    local name=$1
    local command=$2
    
    echo -n "Verificando $name... "
    
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠${NC}"
        ((WARNINGS++))
        return 1
    fi
}

# 1. OpenClaw instalado
echo "=== Verificações de Instalação ==="
check "OpenClaw CLI" "command -v openclaw"

# 2. Node.js
NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//')
if [ ! -z "$NODE_VERSION" ]; then
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)
    if [ $MAJOR_VERSION -ge 20 ]; then
        echo -e "Verificando Node.js... ${GREEN}✓${NC} (v$NODE_VERSION)"
    else
        echo -e "Verificando Node.js... ${YELLOW}⚠${NC} (v$NODE_VERSION - recomendado v20+)"
        ((WARNINGS++))
    fi
else
    echo -e "Verificando Node.js... ${RED}✗${NC}"
    ((ERRORS++))
fi

# 3. Diretório OpenClaw
check "Diretório ~/.openclaw" "[ -d ~/.openclaw ]"

# 4. Arquivo de configuração
check "openclaw.json" "[ -f ~/.openclaw/openclaw.json ]"

echo ""
echo "=== Verificações de Configuração ==="

# 5. JSON válido
if [ -f ~/.openclaw/openclaw.json ]; then
    check "JSON válido" "jq empty ~/.openclaw/openclaw.json"
fi

# 6. API keys configuradas
if [ -f ~/.openclaw/openclaw.json ]; then
    check_warn "API key Anthropic" "grep -q 'ANTHROPIC_API_KEY' ~/.openclaw/openclaw.json || printenv ANTHROPIC_API_KEY"
    check_warn "API key OpenAI" "grep -q 'OPENAI_API_KEY' ~/.openclaw/openclaw.json || printenv OPENAI_API_KEY"
fi

echo ""
echo "=== Verificações de Segurança ==="

# 7. Permissões de arquivo
if [ -f ~/.openclaw/openclaw.json ]; then
    PERMS=$(stat -f "%Lp" ~/.openclaw/openclaw.json 2>/dev/null || stat -c "%a" ~/.openclaw/openclaw.json 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        echo -e "Permissões openclaw.json... ${GREEN}✓${NC} (600)"
    else
        echo -e "Permissões openclaw.json... ${YELLOW}⚠${NC} ($PERMS - recomendado 600)"
        ((WARNINGS++))
    fi
fi

# 8. Gateway binding
if [ -f ~/.openclaw/openclaw.json ]; then
    BIND=$(jq -r '.gateway.bind // "not set"' ~/.openclaw/openclaw.json 2>/dev/null)
    if [ "$BIND" = "loopback" ]; then
        echo -e "Gateway binding... ${GREEN}✓${NC} (loopback)"
    elif [ "$BIND" = "0.0.0.0" ]; then
        echo -e "Gateway binding... ${RED}✗${NC} (0.0.0.0 - INSEGURO!)"
        ((ERRORS++))
    else
        echo -e "Gateway binding... ${YELLOW}⚠${NC} ($BIND)"
        ((WARNINGS++))
    fi
fi

# 9. Auth token configurado
if [ -f ~/.openclaw/openclaw.json ]; then
    TOKEN=$(jq -r '.gateway.auth.token // "not set"' ~/.openclaw/openclaw.json 2>/dev/null)
    if [ "$TOKEN" != "not set" ] && [ ${#TOKEN} -ge 32 ]; then
        echo -e "Gateway auth token... ${GREEN}✓${NC} (${#TOKEN} chars)"
    elif [ "$TOKEN" != "not set" ]; then
        echo -e "Gateway auth token... ${YELLOW}⚠${NC} (${#TOKEN} chars - recomendado 32+)"
        ((WARNINGS++))
    else
        echo -e "Gateway auth token... ${RED}✗${NC} (não configurado)"
        ((ERRORS++))
    fi
fi

echo ""
echo "=== Verificações de Gateway ==="

# 10. Gateway rodando
if pgrep -f "openclaw.*gateway" > /dev/null; then
    echo -e "Gateway process... ${GREEN}✓${NC} (rodando)"
    
    # 11. Porta respondendo
    PORT=$(jq -r '.gateway.port // 18789' ~/.openclaw/openclaw.json 2>/dev/null)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health | grep -q "200"; then
        echo -e "Gateway health endpoint... ${GREEN}✓${NC} (respondendo em porta $PORT)"
    else
        echo -e "Gateway health endpoint... ${YELLOW}⚠${NC} (não respondendo em porta $PORT)"
        ((WARNINGS++))
    fi
else
    echo -e "Gateway process... ${YELLOW}⚠${NC} (não rodando)"
    echo "  Inicie com: openclaw gateway start"
    ((WARNINGS++))
fi

echo ""
echo "=== Verificações de Memória (Opcional) ==="

# 12. PostgreSQL
if command -v psql &> /dev/null; then
    echo -e "PostgreSQL instalado... ${GREEN}✓${NC}"
    
    if pg_isready &> /dev/null; then
        echo -e "PostgreSQL rodando... ${GREEN}✓${NC}"
        
        # 13. Banco openclaw_memory
        if psql -lqt | cut -d \| -f 1 | grep -qw openclaw_memory; then
            echo -e "Banco openclaw_memory... ${GREEN}✓${NC}"
            
            # 14. pgvector extension
            if psql openclaw_memory -tAc "SELECT 1 FROM pg_extension WHERE extname = 'vector';" 2>/dev/null | grep -q "1"; then
                echo -e "Extensão pgvector... ${GREEN}✓${NC}"
            else
                echo -e "Extensão pgvector... ${YELLOW}⚠${NC} (não habilitada)"
                ((WARNINGS++))
            fi
            
            # 15. Schema memory
            if psql openclaw_memory -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name = 'memory';" 2>/dev/null | grep -q "1"; then
                echo -e "Schema memory... ${GREEN}✓${NC}"
            else
                echo -e "Schema memory... ${YELLOW}⚠${NC} (não criado)"
                ((WARNINGS++))
            fi
        else
            echo -e "Banco openclaw_memory... ${YELLOW}⚠${NC} (não encontrado)"
            ((WARNINGS++))
        fi
    else
        echo -e "PostgreSQL rodando... ${YELLOW}⚠${NC} (não rodando)"
        ((WARNINGS++))
    fi
else
    echo -e "PostgreSQL instalado... ${YELLOW}⚠${NC} (não instalado)"
    echo "  Execute: ./scripts/setup-postgres.sh"
    ((WARNINGS++))
fi

echo ""
echo "================================================"
echo "Resumo do Health Check"
echo "================================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todos os checks passaram!${NC}"
    echo ""
    echo "OpenClaw está configurado corretamente."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS aviso(s) encontrado(s)${NC}"
    echo ""
    echo "OpenClaw funcional mas há recomendações para melhorar."
    exit 0
else
    echo -e "${RED}❌ $ERRORS erro(s) encontrado(s), $WARNINGS aviso(s)${NC}"
    echo ""
    echo "Corrija os erros antes de usar OpenClaw."
    exit 1
fi
