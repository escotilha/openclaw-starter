# Conectar Canais

Guia para conectar WhatsApp, Slack, Telegram e Discord ao seu agente OpenClaw.

## Slack

### 1. Criar Slack App

1. Ir em https://api.slack.com/apps
2. "Create New App" → "From scratch"
3. Nome: "OpenClaw" | Workspace: escolher seu workspace

### 2. Configurar Permissões

Em **OAuth & Permissions**, adicionar scopes:

**Bot Token Scopes:**
- `app_mentions:read`
- `channels:history`
- `channels:read`
- `chat:write`
- `files:read`
- `files:write`
- `im:history`
- `im:read`
- `im:write`
- `users:read`

### 3. Habilitar Socket Mode

1. **Settings → Socket Mode** → Enable
2. Gerar **App-Level Token**:
   - Name: "openclaw-socket"
   - Scopes: `connections:write`
   - Copiar token (inicia com `xapp-`)

### 4. Habilitar Event Subscriptions

Em **Event Subscriptions**:
- Enable Events: ON
- Subscribe to bot events:
  - `message.im`
  - `message.channels`
  - `app_mention`

### 5. Instalar no Workspace

1. **Settings → Install App**
2. Copiar **Bot User OAuth Token** (inicia com `xoxb-`)

### 6. Configurar OpenClaw

Adicionar ao `~/.openclaw/.env`:

```bash
SLACK_BOT_TOKEN=xoxb-seu-token-aqui
SLACK_APP_TOKEN=xapp-seu-token-aqui
SLACK_USER_ID=seu-user-id
```

Seu User ID: vá em perfil Slack → "Mais" → "Copiar ID do membro"

Adicionar ao `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "token": "${SLACK_BOT_TOKEN}",
      "appToken": "${SLACK_APP_TOKEN}",
      "socketMode": true,
      "dmPolicy": "allowlist",
      "allowlist": ["${SLACK_USER_ID}"],
      "groupPolicy": "allowlist",
      "allowedChannels": [],
      "defaultAgent": "assistente"
    }
  }
}
```

### 7. Restart & Test

```bash
openclaw gateway restart
```

Mande DM pro bot no Slack!

---

## WhatsApp (Meta Business)

### 1. Criar Meta App

1. Ir em https://developers.facebook.com/apps
2. "Create App" → "Business" → "Messaging"
3. Nome: "OpenClaw Bot"

### 2. Configurar WhatsApp

1. Dashboard → "WhatsApp" → "Getting Started"
2. Selecionar telefone de teste (ou adicionar número business)
3. Copiar:
   - **Access Token** (temporário, expira em 24h)
   - **Phone Number ID**

### 3. Gerar Token Permanente

1. **Settings → Business Settings**
2. **System Users** → "Add" → Nome: "openclaw-bot"
3. Assign to Assets → WhatsApp Account → Full control
4. Generate Token → Permissions: `whatsapp_business_messaging`
5. Copiar token (não expira)

### 4. Configurar Webhook

1. WhatsApp → Configuration → Edit
2. Callback URL: `https://seu-dominio.com/webhook/whatsapp`
3. Verify Token: `seu-verify-token-aleatorio`
4. Subscribe to: `messages`

**Nota:** Precisa de HTTPS público. Use ngrok para teste:

```bash
ngrok http 8080
```

### 5. Configurar OpenClaw

Adicionar ao `~/.openclaw/.env`:

```bash
WHATSAPP_TOKEN=seu-token-permanente
WHATSAPP_PHONE_ID=seu-phone-number-id
WHATSAPP_VERIFY_TOKEN=seu-verify-token
YOUR_PHONE_NUMBER=+5511999999999
```

Adicionar ao `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "token": "${WHATSAPP_TOKEN}",
      "phoneNumberId": "${WHATSAPP_PHONE_ID}",
      "verifyToken": "${WHATSAPP_VERIFY_TOKEN}",
      "webhookPath": "/webhook/whatsapp",
      "dmPolicy": "allowlist",
      "allowlist": ["${YOUR_PHONE_NUMBER}"],
      "defaultAgent": "assistente"
    }
  }
}
```

### 6. Teste

Mande mensagem WhatsApp pro número business!

---

## Telegram

### 1. Criar Bot

1. Abrir Telegram e procurar **@BotFather**
2. Enviar `/newbot`
3. Nome: "OpenClaw Bot"
4. Username: `openclaw_bot` (deve terminar em `_bot`)
5. Copiar **Token** (formato: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Pegar Seu User ID

1. Procurar **@userinfobot**
2. Enviar `/start`
3. Copiar seu **ID** (número)

### 3. Configurar OpenClaw

Adicionar ao `~/.openclaw/.env`:

```bash
TELEGRAM_BOT_TOKEN=seu-token-aqui
TELEGRAM_USER_ID=123456789
```

Adicionar ao `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowlist": ["${TELEGRAM_USER_ID}"],
      "groupPolicy": "allowlist",
      "allowedGroups": [],
      "defaultAgent": "assistente"
    }
  }
}
```

### 4. Restart & Test

```bash
openclaw gateway restart
```

Procure seu bot no Telegram e envie `/start`!

---

## Discord

### 1. Criar Discord App

1. Ir em https://discord.com/developers/applications
2. "New Application" → Nome: "OpenClaw"
3. **Bot** → "Add Bot"
4. Copiar **Token**

### 2. Configurar Permissões

Em **Bot**:
- Enable **Message Content Intent**
- Enable **Server Members Intent**

### 3. Adicionar ao Servidor

1. **OAuth2 → URL Generator**
2. Scopes: `bot`
3. Permissions:
   - Send Messages
   - Read Message History
   - View Channels
   - Attach Files
4. Copiar URL gerada e abrir no navegador
5. Selecionar servidor e autorizar

### 4. Pegar Channel IDs

No Discord:
1. User Settings → Advanced → Enable "Developer Mode"
2. Click direito em canal → "Copy ID"

### 5. Configurar OpenClaw

Adicionar ao `~/.openclaw/.env`:

```bash
DISCORD_BOT_TOKEN=seu-token-aqui
DISCORD_ALLOWED_CHANNELS=1234567890,0987654321
```

Adicionar ao `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "${DISCORD_BOT_TOKEN}",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "allowedChannels": ["${DISCORD_ALLOWED_CHANNELS}"],
      "defaultAgent": "assistente"
    }
  }
}
```

### 6. Restart & Test

```bash
openclaw gateway restart
```

Mencione o bot em canal permitido: `@OpenClaw olá!`

---

## Troubleshooting

### Slack: "not_authed"

Token inválido. Verificar:
1. Token começa com `xoxb-` (não `xoxp-`)
2. App instalado no workspace
3. Variável de ambiente correta

### WhatsApp: "Invalid token"

1. Token permanente (não o temporário)
2. Permissions: `whatsapp_business_messaging`

### Telegram: Bot não responde

1. Verificar User ID numérico (não username)
2. Enviar `/start` primeiro
3. Checar logs: `tail -f ~/.openclaw/logs/gateway.log`

### Discord: "Missing Access"

1. Bot adicionado ao servidor?
2. Channel ID correto?
3. Message Content Intent habilitado?

---

**Próximo:** [MULTI-AGENT.md](MULTI-AGENT.md) — Rodar agentes diferentes em cada canal
