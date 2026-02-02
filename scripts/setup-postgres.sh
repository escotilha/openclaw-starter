#!/bin/bash
set -e

echo "🐘 OpenClaw PostgreSQL Setup Script"
echo "===================================="
echo ""

# Detectar OS
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    OS_TYPE="macOS";;
    Linux*)     OS_TYPE="Linux";;
    *)          OS_TYPE="UNKNOWN";;
esac

echo "🖥️  Sistema operacional: $OS_TYPE"
echo ""

# Instalar PostgreSQL
if [ "$OS_TYPE" = "macOS" ]; then
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew não encontrado. Instale em: https://brew.sh"
        exit 1
    fi
    
    echo "📦 Instalando PostgreSQL 16 via Homebrew..."
    brew install postgresql@16 || true
    
    echo "📦 Instalando pgvector..."
    brew install pgvector || true
    
    echo "🚀 Iniciando serviço PostgreSQL..."
    brew services start postgresql@16
    
    # Adicionar ao PATH
    export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
    
    echo ""
    echo "💡 Adicione ao seu ~/.zshrc ou ~/.bashrc:"
    echo "   export PATH=\"/opt/homebrew/opt/postgresql@16/bin:\$PATH\""
    
elif [ "$OS_TYPE" = "Linux" ]; then
    echo "📦 Instalando PostgreSQL no Linux..."
    
    # Detectar distro
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y postgresql-server postgresql-contrib
        sudo postgresql-setup initdb
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        echo "⚠️  Distro Linux não reconhecida. Instale PostgreSQL manualmente."
        exit 1
    fi
    
    echo "📦 Instalando pgvector..."
    echo "⚠️  pgvector deve ser compilado do fonte no Linux:"
    echo "   git clone https://github.com/pgvector/pgvector.git"
    echo "   cd pgvector && make && sudo make install"
else
    echo "❌ Sistema operacional não suportado: $OS_TYPE"
    exit 1
fi

echo ""
echo "⏳ Aguardando PostgreSQL iniciar..."
sleep 3

# Criar database
echo "🗄️  Criando database openclaw_memory..."
if createdb openclaw_memory 2>/dev/null; then
    echo "✅ Database criado com sucesso"
else
    echo "⚠️  Database já existe ou erro ao criar"
fi

# Habilitar pgvector
echo "🧩 Habilitando extensão pgvector..."
psql openclaw_memory << 'EOF'
CREATE EXTENSION IF NOT EXISTS vector;
\dx
EOF

# Criar schema
echo "📊 Criando schema de memória..."
psql openclaw_memory << 'EOF'
CREATE TABLE IF NOT EXISTS memories (
  id SERIAL PRIMARY KEY,
  agent_id VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  embedding vector(1536),
  metadata JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para busca vetorial
CREATE INDEX IF NOT EXISTS memories_embedding_idx 
ON memories USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Índice para queries por agente
CREATE INDEX IF NOT EXISTS memories_agent_id_idx 
ON memories(agent_id);

-- Índice para queries por data
CREATE INDEX IF NOT EXISTS memories_created_at_idx 
ON memories(created_at DESC);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_memories_updated_at 
BEFORE UPDATE ON memories 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();
EOF

# Verificar
echo ""
echo "✅ Verificando instalação..."
psql openclaw_memory -c "SELECT COUNT(*) as total_memories FROM memories;"

echo ""
echo "🎉 Setup concluído!"
echo ""
echo "📝 Próximos passos:"
echo ""
echo "1. Adicionar ao ~/.openclaw/.env:"
echo "   DATABASE_URL=postgresql://localhost:5432/openclaw_memory"
echo ""
echo "2. Adicionar ao ~/.openclaw/openclaw.json:"
cat << 'JSON'
   {
     "plugins": {
       "memory-postgres": {
         "enabled": true,
         "config": {
           "connectionString": "${DATABASE_URL}",
           "embeddingProvider": "openai",
           "embeddingModel": "text-embedding-3-small",
           "embeddingDimensions": 1536
         }
       }
     }
   }
JSON
echo ""
echo "3. Reiniciar gateway:"
echo "   openclaw gateway restart"
echo ""
echo "4. Testar:"
echo "   psql openclaw_memory -c 'SELECT * FROM memories LIMIT 5;'"
echo ""
echo "📖 Documentação completa: docs/MEMORY.md"
