# Guia de Instalação OpenClaw

Este guia mostra como instalar o OpenClaw do zero no macOS. Para Linux/WSL2, os passos são similares.

## Pré-requisitos

- macOS 12+ (ou Linux/WSL2)
- Node.js 18+ ([instalar aqui](https://nodejs.org/))
- PostgreSQL 14+ ([ver MEMORY.md](MEMORY.md))
- Pelo menos 1 API key (Anthropic, OpenAI ou Google)

## Instalação

### 1. Instalar OpenClaw

```bash
npm install -g openclaw
```

Verificar instalação:

```bash
openclaw --version
```

### 2. Configurar PostgreSQL

Siga o guia completo em [MEMORY.md](MEMORY.md). Resumo:

```bash
# Instalar PostgreSQL + pgvector
brew install postgresql@16 pgvector

# Iniciar serviço
brew services start postgresql@16

# Criar database
createdb openclaw_memory

# Habilitar pgvector
psql openclaw_memory -c "CREATE EXTENSION vector;"
```

Ou use o script automatizado:

```bash
./scripts/setup-postgres.sh
```

### 3. Criar Estrutura de Pastas

```bash
mkdir -p ~/.openclaw
cd ~/.openclaw
```

### 4. Copiar Templates

Do repositório openclaw-starter:

```bash
# Clonar repo
git clone https://github.com/escotilha/openclaw-starter.git /tmp/openclaw-starter

# Copiar templates
cp /tmp/openclaw-starter/templates/single-agent.json ~/.openclaw/openclaw.json
cp /tmp/openclaw-starter/templates/.env.example ~/.openclaw/.env
```

### 5. Configurar Variáveis de Ambiente

Editar `~/.openclaw/.env`:

```bash
nano ~/.openclaw/.env
```

**Mínimo obrigatório:**

```bash
# Token do gateway (gere com: openssl rand -hex 32)
GATEWAY_AUTH_TOKEN=abc123...

# OpenAI para embeddings
OPENAI_API_KEY=sk-...

# Anthropic para Claude (ou use OpenAI/Google)
ANTHROPIC_API_KEY=sk-ant-...

# PostgreSQL
DATABASE_URL=postgresql://localhost:5432/openclaw_memory
```

### 6. Editar Configuração

Editar `~/.openclaw/openclaw.json`:

```bash
nano ~/.openclaw/openclaw.json
```

Personalize:
- Nome do agente
- System prompt
- Modelo (anthropic/claude-sonnet-4, openai/gpt-4o, etc.)

### 7. Verificar Permissões

```bash
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/.env
chmod 600 ~/.openclaw/openclaw.json
```

### 8. Iniciar Gateway

```bash
openclaw gateway start
```

Verificar logs:

```bash
tail -f ~/.openclaw/logs/gateway.log
```

Deve aparecer:

```
[INFO] Gateway started on http://127.0.0.1:8080
[INFO] memory-postgres: Connected to database
[INFO] Agent 'assistente' ready
```

### 9. Testar

Abrir no navegador:

```
http://localhost:8080
```

Deve aparecer o webchat. Mande uma mensagem!

### 10. Health Check

Rode o script de verificação:

```bash
cd /tmp/openclaw-starter
./scripts/health-check.sh
```

## Próximos Passos

Agora que está funcionando:

1. **[SECURITY.md](SECURITY.md)** — Configure segurança (obrigatório!)
2. **[CHANNELS.md](CHANNELS.md)** — Conecte WhatsApp, Slack, Telegram
3. **[SKILLS.md](SKILLS.md)** — Instale skills adicionais
4. **[MULTI-AGENT.md](MULTI-AGENT.md)** — Configure múltiplos agentes

## Troubleshooting

### Gateway não inicia

Verificar porta em uso:

```bash
lsof -i :8080
```

Se ocupada, mude a porta em `openclaw.json`:

```json
{
  "gateway": {
    "port": 8081
  }
}
```

### Erro "Cannot connect to database"

Verificar PostgreSQL rodando:

```bash
brew services list | grep postgresql
```

Se parado:

```bash
brew services start postgresql@16
```

### Erro "Invalid API key"

Verificar `.env`:

```bash
cat ~/.openclaw/.env | grep API_KEY
```

Testar key manualmente:

```bash
# OpenAI
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Anthropic
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"oi"}]}'
```

### Logs não aparecem

Criar pasta de logs:

```bash
mkdir -p ~/.openclaw/logs
```

Restart:

```bash
openclaw gateway restart
```

### Memórias não são salvas

Verificar plugin habilitado em `openclaw.json`:

```json
{
  "plugins": {
    "memory-postgres": {
      "enabled": true
    }
  }
}
```

Verificar tabela criada:

```bash
psql openclaw_memory -c "SELECT COUNT(*) FROM memories;"
```

Se erro "table does not exist", rodar:

```bash
./scripts/setup-postgres.sh
```

## Comandos Úteis

```bash
# Iniciar gateway
openclaw gateway start

# Parar gateway
openclaw gateway stop

# Restart
openclaw gateway restart

# Status
openclaw gateway status

# Logs (tempo real)
tail -f ~/.openclaw/logs/gateway.log

# Ver configuração
cat ~/.openclaw/openclaw.json

# Backup configuração
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
```

## Desinstalação

```bash
# Parar gateway
openclaw gateway stop

# Remover OpenClaw
npm uninstall -g openclaw

# Remover configuração (cuidado!)
rm -rf ~/.openclaw

# Remover database
dropdb openclaw_memory
```

---

**Pronto!** Seu agente está rodando. Agora leia [SECURITY.md](SECURITY.md) antes de conectar canais externos.
