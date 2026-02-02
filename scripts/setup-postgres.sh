#!/bin/bash
# Script de Setup PostgreSQL + pgvector para OpenClaw
# Para macOS (Homebrew)

set -e  # Sair em erro

echo "================================================"
echo "Setup de Memória PostgreSQL para OpenClaw"
echo "================================================"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem Cor

# Verificar se Homebrew está instalado
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew não encontrado${NC}"
    echo "Instale Homebrew primeiro: https://brew.sh"
    exit 1
fi

echo -e "${GREEN}✓ Homebrew encontrado${NC}"

# Verificar se PostgreSQL está instalado
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando PostgreSQL...${NC}"
    brew install postgresql@16
    echo -e "${GREEN}✓ PostgreSQL instalado${NC}"
else
    echo -e "${GREEN}✓ PostgreSQL já instalado${NC}"
fi

# Iniciar serviço PostgreSQL
echo -e "${YELLOW}🚀 Iniciando serviço PostgreSQL...${NC}"
brew services start postgresql@16
sleep 2  # Aguardar serviço iniciar

# Verificar se PostgreSQL está rodando
if ! pg_isready &> /dev/null; then
    echo -e "${RED}❌ Serviço PostgreSQL não está rodando${NC}"
    echo "Tente: brew services restart postgresql@16"
    exit 1
fi

echo -e "${GREEN}✓ Serviço PostgreSQL rodando${NC}"

# Instalar pgvector
if ! brew list pgvector &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando pgvector...${NC}"
    brew install pgvector
    echo -e "${GREEN}✓ pgvector instalado${NC}"
else
    echo -e "${GREEN}✓ pgvector já instalado${NC}"
fi

# Criar banco de dados
echo -e "${YELLOW}📂 Criando banco openclaw_memory...${NC}"
if psql postgres -lqt | cut -d \| -f 1 | grep -qw openclaw_memory; then
    echo -e "${YELLOW}⚠ Banco openclaw_memory já existe${NC}"
    read -p "Dropar e recriar? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        dropdb openclaw_memory
        createdb openclaw_memory
        echo -e "${GREEN}✓ Banco recriado${NC}"
    else
        echo -e "${YELLOW}Pulando criação do banco${NC}"
    fi
else
    createdb openclaw_memory
    echo -e "${GREEN}✓ Banco criado${NC}"
fi

# Habilitar extensão pgvector
echo -e "${YELLOW}🧩 Habilitando extensão pgvector...${NC}"
psql openclaw_memory -c "CREATE EXTENSION IF NOT EXISTS vector;" &> /dev/null
echo -e "${GREEN}✓ Extensão pgvector habilitada${NC}"

# Criar schema
echo -e "${YELLOW}📋 Criando schema de memória...${NC}"

psql openclaw_memory <<'SQL'
-- Criar schema memory
CREATE SCHEMA IF NOT EXISTS memory;

-- Criar tabela memories com embeddings vetoriais
CREATE TABLE IF NOT EXISTS memory.memories (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB,
    agent_id VARCHAR(100),
    session_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Criar índices para busca de similaridade vetorial
CREATE INDEX IF NOT EXISTS memories_embedding_idx 
ON memory.memories 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Criar índices para queries de metadata
CREATE INDEX IF NOT EXISTS memories_agent_id_idx ON memory.memories (agent_id);
CREATE INDEX IF NOT EXISTS memories_session_id_idx ON memory.memories (session_id);
CREATE INDEX IF NOT EXISTS memories_created_at_idx ON memory.memories (created_at);
CREATE INDEX IF NOT EXISTS memories_metadata_idx ON memory.memories USING GIN (metadata);

-- Criar função para atualizar timestamps
CREATE OR REPLACE FUNCTION memory.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar trigger para atualização automática de timestamps
DROP TRIGGER IF EXISTS update_memories_updated_at ON memory.memories;
CREATE TRIGGER update_memories_updated_at 
BEFORE UPDATE ON memory.memories
FOR EACH ROW 
EXECUTE FUNCTION memory.update_updated_at_column();
SQL

echo -e "${GREEN}✓ Schema criado${NC}"

# Verificar instalação
echo ""
echo -e "${YELLOW}🔍 Verificando instalação...${NC}"

# Verificar versão PostgreSQL
PG_VERSION=$(psql --version | awk '{print $3}')
echo -e "Versão PostgreSQL: ${GREEN}$PG_VERSION${NC}"

# Verificar versão pgvector
PGVECTOR_VERSION=$(psql openclaw_memory -tAc "SELECT extversion FROM pg_extension WHERE extname = 'vector';")
echo -e "Versão pgvector: ${GREEN}$PGVECTOR_VERSION${NC}"

# Verificar schema
TABLE_COUNT=$(psql openclaw_memory -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'memory';")
echo -e "Tabelas memory criadas: ${GREEN}$TABLE_COUNT${NC}"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✅ Setup PostgreSQL completo!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Próximos passos:"
echo ""
echo "1. Obtenha sua API key OpenAI para embeddings:"
echo "   https://platform.openai.com/api-keys"
echo ""
echo "2. Atualize openclaw.json com:"
echo ""
echo "   {
  \"plugins\": {
    \"slots\": {
      \"memory\": \"memory-postgres\"
    },
    \"entries\": {
      \"memory-postgres\": {
        \"enabled\": true,
        \"config\": {
          \"host\": \"localhost\",
          \"port\": 5432,
          \"database\": \"openclaw_memory\",
          \"user\": \"$(whoami)\",
          \"password\": \"\",
          \"embeddingApiKey\": \"\${OPENAI_API_KEY}\",
          \"embeddingModel\": \"text-embedding-3-small\"
        }
      }
    }
  }
}"
echo ""
echo "3. Defina variável de ambiente:"
echo "   export OPENAI_API_KEY=\"sua-key-aqui\""
echo ""
echo "4. Reinicie gateway OpenClaw:"
echo "   openclaw gateway restart"
echo ""
echo -e "${YELLOW}Conexão com banco:${NC}"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: openclaw_memory"
echo "  User: $(whoami)"
echo ""
echo "Testar conexão:"
echo "  psql openclaw_memory -c \"SELECT COUNT(*) FROM memory.memories;\""
echo ""
