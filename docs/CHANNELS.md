# Guia de Configuração de Canais

**Guia completo para configurar canais WhatsApp, Slack, Telegram e Discord no OpenClaw.**

## Canais Suportados

| Canal | Protocolo | Método de Auth | Multi-Conta |
|-------|-----------|----------------|-------------|
| WhatsApp | baileys | QR code scan | ✅ Sim |
| Slack | Socket Mode | OAuth tokens | ✅ Sim |
| Telegram | Bot API | Bot token | ✅ Sim |
| Discord | Discord.js | Bot token | ✅ Sim |

## WhatsApp

### Setup Básico

```json
{
  "channels": {
    "whatsapp": {
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "mediaMaxMb": 50,
      "debounceMs": 2000,
      "sendReadReceipts": true,
      "allowFrom": [
        "+5511999999999"
      ]
    }
  },
  "plugins": {
    "entries": {
      "whatsapp": {
        "enabled": true
      }
    }
  }
}
```

### Processo de Pareamento

```bash
openclaw gateway start
openclaw gateway logs
# Escaneie o QR code que aparece com WhatsApp no celular
```

**⚠️ Importante**: Sempre use `debounceMs >= 2000` para WhatsApp para evitar rate limits.

## Slack

### Criar App Slack

1. Acesse https://api.slack.com/apps
2. **Create New App** → **From scratch**
3. Habilite **Socket Mode**
4. Adicione escopos de bot necessários
5. Instale no workspace

### Configuração

```json
{
  "channels": {
    "slack": {
      "mode": "socket",
      "enabled": true,
      "userTokenReadOnly": true,
      "groupPolicy": "allowlist",
      "accounts": {
        "meuworkspace": {
          "botToken": "${SLACK_BOT_TOKEN}",
          "appToken": "${SLACK_APP_TOKEN}",
          "groups": {
            "C01234ABCDE": true
          }
        }
      }
    }
  }
}
```

## Telegram

### Criar Bot

1. Abra Telegram, procure **@BotFather**
2. `/newbot` e siga instruções
3. Salve o token do bot

### Configuração

```json
{
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["@seunome"],
      "groupPolicy": "allowlist"
    }
  }
}
```

## Discord

### Criar Bot Discord

1. Acesse https://discord.com/developers/applications
2. **New Application**
3. Vá em **Bot** → **Add Bot**
4. Habilite **Message Content Intent**
5. Copie o token

### Configuração

```json
{
  "channels": {
    "discord": {
      "botToken": "${DISCORD_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "groupPolicy": "allowlist"
    }
  }
}
```

## Políticas de Segurança

### Políticas de DM Recomendadas

| Canal | Política | Razão |
|-------|----------|-------|
| WhatsApp | `pairing` | Uso pessoal, família/amigos |
| Slack | `pairing` | Comunicação interna de time |
| Telegram | `allowlist` | Bot público, mais controle |
| Discord | `allowlist` | Servidores públicos, acesso estrito |

### Política de Grupos

**Sempre use `allowlist`** para canais de grupo:

```json
{
  "groupPolicy": "allowlist",
  "groups": {
    "ID-DO-GRUPO": true
  }
}
```

---

**Próximo**: Configure [Segurança](SECURITY.md) para hardening dos canais.
