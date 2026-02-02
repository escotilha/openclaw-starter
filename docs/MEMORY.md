# Guia de Setup de Memória PostgreSQL

**Memória persistente pronta para produção com PostgreSQL + pgvector e embeddings OpenAI.**

Este guia explica como configurar o backend de memória mais poderoso do OpenClaw. Ao contrário do LanceDB padrão (baseado em arquivo), PostgreSQL oferece:

- ✅ **Memória persistente** entre reinicializações
- ✅ **Memória compartilhada multi-agent** (opcional)
- ✅ **Busca semântica** via pgvector
- ✅ **Dados estruturados** com queries relacionais
- ✅ **Confiabilidade enterprise** e backups

## Pré-requisitos

- macOS 12+ (instruções para macOS; adapte para Linux)
- Homebrew instalado
- OpenClaw instalado (veja [INSTALL.md](INSTALL.md))
- API key OpenAI (para embeddings)

## Início Rápido (Automatizado)

Fornecemos um script que automatiza todo o setup:

```bash
cd scripts
./setup-postgres.sh
```

Este script vai:
1. Instalar PostgreSQL via Homebrew
2. Instalar extensão pgvector
3. Criar banco de dados `openclaw_memory`
4. Configurar schema com suporte a vetores
5. Configurar OpenClaw para usá-lo

**Pule para [Verificação](#verificação) se o script funcionar.**

## Instalação Manual

Se preferir setup manual ou o script falhar:

### Passo 1: Instalar PostgreSQL

```bash
# Instalar PostgreSQL via Homebrew
brew install postgresql@16

# Iniciar serviço PostgreSQL
brew services start postgresql@16

# Verificar se está rodando
psql postgres -c "SELECT version();"
```

Saída esperada:
```
PostgreSQL 16.x on arm64-apple-darwin...
```

### Passo 2: Instalar Extensão pgvector

```bash
# Instalar pgvector
brew install pgvector

# Verificar instalação
brew list pgvector
```

### Passo 3: Criar Banco de Dados

```bash
# Criar banco de dados
createdb openclaw_memory

# Verificar criação
psql -l | grep openclaw_memory
```

### Passo 4: Habilitar Extensão pgvector

```bash
psql openclaw_memory -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

Verificar:
```bash
psql openclaw_memory -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
```

Saída esperada:
```
 oid  | extname | extowner | extnamespace | extrelocatable | extversion | ...
------+---------+----------+--------------+----------------+------------+-----
 16389| vector  |       10 |         2200 | t              | 0.8.1      | ...
```

### Passo 5: Configurar Schema de Memória

Crie o schema com suporte a embeddings vetoriais:

```sql
-- Conectar ao banco
psql openclaw_memory

-- Criar schema memory
CREATE SCHEMA IF NOT EXISTS memory;

-- Criar tabela memories com embeddings vetoriais
CREATE TABLE IF NOT EXISTS memory.memories (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536), -- Dimensão OpenAI text-embedding-3-small
    metadata JSONB,
    agent_id VARCHAR(100),
    session_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Criar índice para busca de similaridade vetorial
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
CREATE TRIGGER update_memories_updated_at 
BEFORE UPDATE ON memory.memories
FOR EACH ROW 
EXECUTE FUNCTION memory.update_updated_at_column();
```

Salve isso como `memory_schema.sql` e execute:

```bash
psql openclaw_memory < memory_schema.sql
```

## Configurar OpenClaw

### Passo 1: Obter Sua API Key OpenAI

Você precisa de uma API key OpenAI para embeddings. Obtenha em https://platform.openai.com/api-keys

### Passo 2: Atualizar openclaw.json

Edite `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "slots": {
      "memory": "memory-postgres"
    },
    "entries": {
      "memory-lancedb": {
        "enabled": false
      },
      "memory-postgres": {
        "enabled": true,
        "config": {
          "host": "localhost",
          "port": 5432,
          "database": "openclaw_memory",
          "user": "seu-usuario",
          "password": "",
          "embeddingApiKey": "sua-openai-api-key-aqui",
          "embeddingModel": "text-embedding-3-small"
        }
      }
    }
  }
}
```

**Campos importantes:**

| Campo | Valor | Notas |
|-------|-------|-------|
| `host` | `localhost` | Para banco local |
| `port` | `5432` | Porta padrão PostgreSQL |
| `database` | `openclaw_memory` | Deve bater com banco criado |
| `user` | Seu username macOS | Geralmente seu nome curto |
| `password` | Vazio para local | Defina para conexões remotas |
| `embeddingApiKey` | Sua key OpenAI | Para text-embedding-3-small |
| `embeddingModel` | `text-embedding-3-small` | Modelo recomendado |

### Passo 3: Obter Seu Username do Banco

```bash
# Seu username geralmente é seu username macOS
whoami
```

Use isso como `user` no config.

### Passo 4: (Opcional) Definir Senha do Banco

Para desenvolvimento local, pode pular isso. Para produção:

```bash
# Definir senha para seu usuário
psql postgres -c "ALTER USER seunomeusuario WITH PASSWORD 'senha-segura-aqui';"
```

Então atualize o config:

```json
{
  "plugins": {
    "entries": {
      "memory-postgres": {
        "config": {
          "password": "senha-segura-aqui"
        }
      }
    }
  }
}
```

**Melhor**: Use variável de ambiente:

```bash
export OPENCLAW_DB_PASSWORD="senha-segura-aqui"
```

E no config:
```json
{
  "env": {
    "OPENCLAW_DB_PASSWORD": "${OPENCLAW_DB_PASSWORD}"
  }
}
```

## Verificação

### Teste 1: Conexão com Banco

```bash
psql -h localhost -p 5432 -U $(whoami) -d openclaw_memory -c "\dt memory.*"
```

Saída esperada:
```
           List of relations
 Schema  |   Name    | Type  |  Owner   
---------+-----------+-------+----------
 memory  | memories  | table | username
```

### Teste 2: Extensão pgvector

```bash
psql openclaw_memory -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';"
```

Saída esperada:
```
 extversion 
------------
 0.8.1
```

### Teste 3: Plugin de Memória OpenClaw

Reinicie gateway OpenClaw:

```bash
openclaw gateway restart
```

Verifique logs para inicialização do plugin de memória:

```bash
openclaw gateway logs | grep memory
```

Saída esperada:
```
[memory-postgres] Connected to database openclaw_memory
[memory-postgres] Embedding model: text-embedding-3-small
```

### Teste 4: Criar uma Memória

Inicie sessão de chat:

```bash
openclaw chat
```

Diga algo memorável:

```
Você: Lembre que minha cor favorita é azul.
Agente: Vou lembrar que sua cor favorita é azul.
```

Verifique o banco:

```bash
psql openclaw_memory -c "SELECT content FROM memory.memories ORDER BY created_at DESC LIMIT 1;"
```

Você deve ver sua memória armazenada!

### Teste 5: Recuperar uma Memória

Em uma nova sessão:

```bash
openclaw chat
```

Pergunte:

```
Você: Qual é minha cor favorita?
Agente: Sua cor favorita é azul.
```

Se funcionar, memória está funcionando! 🎉

## Configuração Avançada

### Memória Compartilhada Multi-Agent

Para compartilhar memória entre todos agentes:

```json
{
  "agents": {
    "defaults": {
      "memory": {
        "shared": true
      }
    }
  }
}
```

### Memória Específica por Agente

Para isolar memória por agente:

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "memory": {
          "shared": false,
          "namespace": "main"
        }
      },
      {
        "id": "cris",
        "memory": {
          "shared": false,
          "namespace": "cris"
        }
      }
    ]
  }
}
```

## Modelos de Embedding

### Recomendado: text-embedding-3-small

- **Dimensão**: 1536
- **Custo**: $0.02 / 1M tokens
- **Performance**: Excelente para maioria dos casos
- **Velocidade**: Rápido

### Alternativa: text-embedding-3-large

Para maior precisão:

```json
{
  "embeddingModel": "text-embedding-3-large"
}
```

Atualize schema:
```sql
ALTER TABLE memory.memories ALTER COLUMN embedding TYPE vector(3072);
```

**Custo**: $0.13 / 1M tokens (6.5x mais caro)

## Otimização de Performance

### Otimização de Índices

Para datasets grandes (>100k memórias):

```sql
-- Aumentar lists para melhor performance
DROP INDEX IF EXISTS memory.memories_embedding_idx;

CREATE INDEX memories_embedding_idx 
ON memory.memories 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 1000);
```

### Connection Pooling

Para deployments de alto tráfego:

```json
{
  "plugins": {
    "entries": {
      "memory-postgres": {
        "config": {
          "pool": {
            "min": 2,
            "max": 10
          }
        }
      }
    }
  }
}
```

## Backup & Restore

### Backup

```bash
# Backup de banco inteiro
pg_dump openclaw_memory > backup_$(date +%Y%m%d).sql

# Backup apenas schema memory
pg_dump -n memory openclaw_memory > backup_memory_$(date +%Y%m%d).sql
```

### Restore

```bash
# Restaurar de backup
psql openclaw_memory < backup_20260201.sql
```

### Backups Automatizados

Adicione ao crontab:

```bash
# Backup diário às 2am
0 2 * * * pg_dump openclaw_memory > ~/backups/openclaw_$(date +\%Y\%m\%d).sql
```

## Troubleshooting

### Problema: "relation 'memory.memories' does not exist"

**Solução**: Schema não criado. Execute o SQL do schema:

```bash
psql openclaw_memory < scripts/memory_schema.sql
```

### Problema: "extension 'vector' does not exist"

**Solução**: pgvector não instalado:

```bash
brew install pgvector
psql openclaw_memory -c "CREATE EXTENSION vector;"
```

### Problema: "connection refused"

**Solução**: PostgreSQL não rodando:

```bash
brew services start postgresql@16
```

### Problema: "authentication failed"

**Solução**: Senha incorreta ou username errado:

```bash
# Verifique seu username
whoami

# Resete senha
psql postgres -c "ALTER USER $(whoami) WITH PASSWORD 'novasenha';"
```

## Estimativa de Custos

**Custos de embeddings**:
- text-embedding-3-small: ~$0.02 por 1M tokens
- Memória média: ~50 tokens
- 1000 memórias: ~$0.001 (praticamente de graça)

**Hospedagem de banco**:
- Local: Grátis
- AWS RDS (db.t3.micro): ~$15/mês
- DigitalOcean (1GB): ~$15/mês

## Próximos Passos

- **Segurança**: Veja [SECURITY.md](SECURITY.md) para segurança do banco
- **Multi-Agent**: Veja [MULTI-AGENT.md](MULTI-AGENT.md) para memória compartilhada
- **Skills**: Veja [SKILLS.md](SKILLS.md) para skills que usam memória

---

**Parabéns!** Você agora tem memória persistente enterprise. 🧠
