# Guia de Hardening de Segurança

**Configuração de segurança enterprise para deployments OpenClaw.**

## Os 12 Domínios de Segurança

### 1. Exposição do Gateway 🔴 Crítico

```json
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "gere-com-openssl-rand-hex-32"
    }
  }
}
```

**Gerar token forte:**
```bash
openssl rand -hex 32
```

### 2. Política de DMs 🟠 Alto

```json
{
  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing",
      "allowFrom": ["+5511999999999"]
    }
  }
}
```

**Opções:**
- `pairing` - Requer código de pareamento (recomendado)
- `allowlist` - Apenas usuários listados
- `open` - ⛔ NUNCA use em produção

### 3. Controle de Acesso a Grupos 🟠 Alto

```json
{
  "channels": {
    "slack": {
      "groupPolicy": "allowlist",
      "groups": {
        "C01234ABCDE": true
      }
    }
  }
}
```

### 4. Segurança de Credenciais 🔴 Crítico

**Permissões de arquivo:**
```bash
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/credentials/*
```

**Use variáveis de ambiente:**
```bash
export ANTHROPIC_API_KEY="sua-key-aqui"
export OPENAI_API_KEY="sua-key-aqui"
```

### 5. Binding de Rede 🟠 Alto

**Local apenas:**
```json
{
  "gateway": {
    "bind": "loopback"
  }
}
```

**Acesso remoto via Tailscale:**
```json
{
  "gateway": {
    "tailscale": {
      "mode": "on"
    }
  }
}
```

### 6. Limites de Mídia e Rate 🟡 Médio

```json
{
  "channels": {
    "whatsapp": {
      "mediaMaxMb": 50,
      "debounceMs": 2000
    }
  },
  "agents": {
    "defaults": {
      "maxConcurrent": 2
    }
  }
}
```

### 7. Tokens Slack Read-Only 🟠 Alto

```json
{
  "channels": {
    "slack": {
      "userTokenReadOnly": true
    }
  }
}
```

### 8. Permissões de Arquivo 🟡 Médio

```bash
#!/bin/bash
# Script de verificação
chmod 700 ~/.openclaw
find ~/.openclaw -name "*.json" -exec chmod 600 {} \;
find ~/.openclaw/credentials -type f -exec chmod 600 {} \;
```

### 9. Logging & Redação 🟡 Médio

```json
{
  "logging": {
    "level": "info",
    "redactSensitive": "tools"
  }
}
```

### 10. Segurança do Banco de Dados 🔴 Crítico

**Desenvolvimento local:**
```json
{
  "plugins": {
    "entries": {
      "memory-postgres": {
        "config": {
          "host": "localhost",
          "password": ""
        }
      }
    }
  }
}
```

**Produção:**
```json
{
  "plugins": {
    "entries": {
      "memory-postgres": {
        "config": {
          "host": "db.exemplo.com",
          "password": "${DB_PASSWORD}",
          "ssl": true
        }
      }
    }
  }
}
```

### 11. Proteção contra Prompt Injection 🟡 Médio

**Estratégias:**
1. Manter DMs travados (pairing/allowlist)
2. Usar mention gating em grupos
3. Tratar links como hostis
4. Sandboxing de conteúdo externo
5. Usar modelos instruction-hardened

### 12. Backup & Recuperação 🟡 Médio

```bash
#!/bin/bash
# backup-openclaw.sh
BACKUP_DIR=~/openclaw-backups
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
cp ~/.openclaw/openclaw.json $BACKUP_DIR/openclaw_$DATE.json
pg_dump openclaw_memory > $BACKUP_DIR/db_$DATE.sql

find $BACKUP_DIR -type f -mtime +7 -delete
```

## Checklist de Segurança

### Crítico 🔴
- [ ] Gateway bound a `loopback`
- [ ] Token forte de auth (32+ chars)
- [ ] Política DM: `pairing` ou `allowlist`
- [ ] Política de grupo: `allowlist`
- [ ] Permissões de arquivo: 700 (dirs), 600 (arquivos)
- [ ] API keys em variáveis de ambiente

### Alto 🟠
- [ ] WhatsApp debounce ≥ 2000ms
- [ ] Rate limits configurados
- [ ] Tokens Slack read-only
- [ ] Limites de mídia definidos
- [ ] Logs redacted

### Médio 🟡
- [ ] Rotação de logs configurada
- [ ] Backups diários automatizados
- [ ] Secret scanning habilitado
- [ ] Firewall rules configuradas

## Resposta a Incidentes

### 1. Contenção
```bash
openclaw gateway stop
chmod 000 ~/.openclaw/openclaw.json
```

### 2. Investigação
```bash
tail -100 ~/.openclaw/logs/gateway.log
grep "unauthorized\|failed" ~/.openclaw/logs/*.log
```

### 3. Rotação
```bash
NEW_TOKEN=$(openssl rand -hex 32)
# Rotacione API keys em consoles dos provedores
```

---

**Próximo**: Veja [Multi-Agent](MULTI-AGENT.md) para isolamento de segurança entre agentes.
