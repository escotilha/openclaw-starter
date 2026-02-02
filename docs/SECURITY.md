# Hardening de Segurança

**⚠️ LEIA ANTES DE EXPOR SEU AGENTE À INTERNET!**

OpenClaw é poderoso. Sem proteção, você está dando acesso root da sua vida a qualquer pessoa. Este guia mostra como trancar as portas.

## 🔐 Checklist de Segurança Obrigatória

- [ ] Token de autenticação configurado
- [ ] Gateway ouvindo apenas em loopback (127.0.0.1)
- [ ] DM policy definido (allowlist ou pairing)
- [ ] Group policy: allowlist
- [ ] Limites de tamanho de media configurados
- [ ] Permissões de arquivo corretas (chmod 700)
- [ ] API keys em `.env`, nunca em código
- [ ] Backup de memórias criptografado

## 1. Token de Autenticação

Gere um token forte:

```bash
openssl rand -hex 32
```

Adicione ao `~/.openclaw/.env`:

```bash
GATEWAY_AUTH_TOKEN=seu-token-aleatorio-de-64-caracteres-aqui
```

Configure no `~/.openclaw/openclaw.json`:

```json
{
  "gateway": {
    "port": 8080,
    "auth": {
      "enabled": true,
      "token": "${GATEWAY_AUTH_TOKEN}"
    }
  }
}
```

**Teste:**

```bash
# Sem token — deve falhar
curl http://localhost:8080/api/status

# Com token — deve funcionar
curl -H "Authorization: Bearer SEU-TOKEN" http://localhost:8080/api/status
```

## 2. Binding Seguro

**NUNCA** faça bind em `0.0.0.0` (expõe para toda a rede).

### ✅ Correto (loopback apenas)

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 8080
  }
}
```

### ❌ ERRADO (exposto na rede)

```json
{
  "gateway": {
    "host": "0.0.0.0",  // ⚠️ NUNCA FAÇA ISSO!
    "port": 8080
  }
}
```

### Acesso Remoto Seguro

Use Tailscale ou SSH tunnel:

**Opção 1: Tailscale (recomendado)**

```bash
# Instalar Tailscale
brew install tailscale
tailscale up

# Gateway continua em 127.0.0.1, acesse via Tailscale IP
# Ex: http://100.64.x.x:8080
```

**Opção 2: SSH Tunnel**

```bash
ssh -L 8080:127.0.0.1:8080 usuario@seu-servidor.com
```

## 3. Política de DMs

Controle **quem** pode mandar DM pro seu agente.

### Opção A: Allowlist (mais seguro)

Apenas IDs específicos podem iniciar conversa:

```json
{
  "channels": {
    "slack": {
      "dmPolicy": "allowlist",
      "allowlist": ["U01234ABCD", "U56789EFGH"]
    },
    "whatsapp": {
      "dmPolicy": "allowlist",
      "allowlist": ["+5511999999999", "+5511888888888"]
    }
  }
}
```

### Opção B: Pairing (flexível)

Qualquer pessoa pode pedir acesso, você aprova:

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "pairing",
      "autoApprove": false
    }
  }
}
```

Quando alguém mandar DM:

```
[INFO] Pairing request from @fulano (ID: 123456789)
```

Aprovar:

```bash
openclaw pairing approve telegram 123456789
```

### ❌ NUNCA use "open"

```json
{
  "dmPolicy": "open"  // ⚠️ Qualquer pessoa do mundo pode falar com seu agente!
}
```

## 4. Política de Grupos

**SEMPRE** use allowlist para grupos:

```json
{
  "channels": {
    "discord": {
      "groupPolicy": "allowlist",
      "allowedGroups": ["1234567890", "0987654321"]
    },
    "slack": {
      "groupPolicy": "allowlist",
      "allowedChannels": ["C01234ABCD", "C56789EFGH"]
    }
  }
}
```

## 5. Limites de Media

Proteja contra ataques de DoS com arquivos grandes:

```json
{
  "media": {
    "maxSizeMB": 50,
    "maxDuration": 600,
    "allowedTypes": ["image/jpeg", "image/png", "audio/mpeg", "video/mp4"],
    "scanForMalware": true
  }
}
```

## 6. Permissões de Arquivo

Proteja a pasta OpenClaw:

```bash
# Apenas você pode ler/escrever
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/.env
chmod 600 ~/.openclaw/openclaw.json

# Verificar
ls -la ~/.openclaw
# Deve mostrar: drwx------ (700)
```

## 7. Slack: Tokens Read-Only

Para Slack workspace que você **não** controla, use User Token com scopes mínimos:

```
users:read
channels:read
groups:read
im:read
mpim:read
```

**NUNCA** use Bot Token em workspace de terceiros (pode ler DMs privadas).

Configure:

```json
{
  "channels": {
    "slack-readonly": {
      "enabled": true,
      "token": "${SLACK_USER_TOKEN}",
      "type": "user",
      "dmPolicy": "none",
      "groupPolicy": "allowlist",
      "allowedChannels": ["C01234ABCD"]
    }
  }
}
```

## 8. PostgreSQL

Proteja o banco de memórias:

### Senha para Usuário Local

```bash
psql postgres
```

```sql
ALTER USER psm2 WITH PASSWORD 'senha-forte-aqui';
\q
```

Atualize connection string:

```json
{
  "plugins": {
    "memory-postgres": {
      "config": {
        "connectionString": "postgresql://psm2:senha-forte-aqui@localhost:5432/openclaw_memory"
      }
    }
  }
}
```

### Firewall (Produção)

Se PostgreSQL estiver em servidor remoto:

```bash
# ufw (Ubuntu/Debian)
sudo ufw allow from 192.168.1.0/24 to any port 5432

# iptables
sudo iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 5432 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP
```

## 9. Backup Criptografado

Criptografe backups de memória:

```bash
# Backup + encrypt
pg_dump openclaw_memory | gzip | openssl enc -aes-256-cbc -salt -out backup-$(date +%Y%m%d).sql.gz.enc

# Decrypt + restore
openssl enc -aes-256-cbc -d -in backup-20260201.sql.gz.enc | gunzip | psql openclaw_memory
```

## 10. Logs Seguros

Não logue dados sensíveis:

```json
{
  "logging": {
    "level": "info",
    "redactPatterns": [
      "password",
      "token",
      "api_key",
      "secret",
      "credit_card"
    ]
  }
}
```

## 11. Rate Limiting

Proteja contra spam:

```json
{
  "rateLimit": {
    "enabled": true,
    "maxMessagesPerMinute": 10,
    "maxMessagesPerHour": 100,
    "burstSize": 5
  }
}
```

## 12. Auditoria

Monitore atividade suspeita:

```bash
# Ver últimas 100 mensagens
tail -100 ~/.openclaw/logs/gateway.log

# Filtrar por usuário
grep "user:U12345" ~/.openclaw/logs/gateway.log

# Alertar em erro
tail -f ~/.openclaw/logs/gateway.log | grep ERROR --line-buffered | \
  while read line; do
    echo "$line" | mail -s "OpenClaw Error" seu@email.com
  done
```

## 13. Skills Perigosos

Alguns skills são **high-risk**. Entenda antes de habilitar:

| Skill | Risco | Quando Usar |
|---|---|---|
| `exec` | 🔴 Crítico | Apenas localhost, nunca em produção |
| `file-access` | 🟠 Alto | Limite paths com allowlist |
| `web-browser` | 🟡 Médio | Seguro com URL allowlist |
| `email` | 🟡 Médio | OK se não tem acesso a inbox sensível |
| `calendar` | 🟢 Baixo | Geralmente seguro |

Configure allowlist para skills sensíveis:

```json
{
  "skills": {
    "file-access": {
      "enabled": true,
      "allowedPaths": [
        "/Users/voce/Documents/openclaw-workspace",
        "/tmp"
      ],
      "deniedPaths": [
        "/Users/voce/.ssh",
        "/Users/voce/.aws"
      ]
    }
  }
}
```

## 14. Variáveis de Ambiente

**NUNCA** commite `.env` ou `openclaw.json` com credentials reais.

### .gitignore

```gitignore
.env
.env.local
openclaw.json
*.log
backups/
```

### Template para Time

Crie `.env.example`:

```bash
# OpenAI (embeddings + opcional LLM)
OPENAI_API_KEY=sk-sua-key-aqui

# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-sua-key-aqui

# Gateway
GATEWAY_AUTH_TOKEN=openssl-rand-hex-32

# Slack
SLACK_BOT_TOKEN=xoxb-sua-token
SLACK_APP_TOKEN=xapp-sua-token

# PostgreSQL
DATABASE_URL=postgresql://user:pass@localhost:5432/openclaw_memory
```

Time clona repo, copia `.env.example` → `.env` e preenche.

## 15. Incident Response

Se credenciais vazarem:

1. **Revogar imediatamente** (Slack, OpenAI, Anthropic dashboards)
2. Gerar novas keys
3. Atualizar `.env` e `openclaw.json`
4. Restart gateway: `openclaw gateway restart`
5. Checar logs para atividade suspeita
6. Rodar `./scripts/health-check.sh`

## Próximos Passos

- [CHANNELS.md](CHANNELS.md) — Conectar canais com segurança
- [MULTI-AGENT.md](MULTI-AGENT.md) — Isolar agentes por permissões
- [MEMORY.md](MEMORY.md) — Backup seguro de memórias

---

**Regra de Ouro:** Se você não faria em produção com SSH root, não faça com OpenClaw.
