# OpenClaw Starter Kit

**Guia completo para instalar e configurar o OpenClaw** — framework de agentes de IA autônomos com memória PostgreSQL, hardening de segurança e templates de configuração.

## 🚀 Quick Start

```bash
# 1. Instalar OpenClaw
npm install -g openclaw

# 2. Configurar PostgreSQL com memória vetorial
./scripts/setup-postgres.sh

# 3. Criar configuração inicial
cp templates/single-agent.json ~/.openclaw/openclaw.json
cp templates/.env.example ~/.openclaw/.env

# 4. Editar com suas API keys
nano ~/.openclaw/.env
nano ~/.openclaw/openclaw.json

# 5. Iniciar o gateway
openclaw gateway start

# 6. Verificar instalação
./scripts/health-check.sh
```

## 📚 Documentação

- **[INSTALL.md](docs/INSTALL.md)** — Instalação completa do OpenClaw
- **[MEMORY.md](docs/MEMORY.md)** — Configurar PostgreSQL + pgvector para memória
- **[SECURITY.md](docs/SECURITY.md)** — Hardening de segurança (obrigatório!)
- **[CHANNELS.md](docs/CHANNELS.md)** — Conectar WhatsApp, Slack, Telegram, Discord
- **[MULTI-AGENT.md](docs/MULTI-AGENT.md)** — Rodar múltiplos agentes
- **[SKILLS.md](docs/SKILLS.md)** — Skills recomendados

## 📁 O Que Tem Aqui

```
openclaw-starter/
├── templates/
│   ├── single-agent.json      # Setup mínimo (1 agente)
│   ├── multi-agent.json       # 2-3 agentes com roles diferentes
│   └── .env.example           # Variáveis de ambiente
├── scripts/
│   ├── setup-postgres.sh      # Setup automatizado do PostgreSQL
│   └── health-check.sh        # Verificar instalação
└── docs/
    ├── INSTALL.md             # Guia de instalação
    ├── MEMORY.md              # PostgreSQL + pgvector
    ├── SECURITY.md            # Hardening de segurança
    ├── CHANNELS.md            # Conectar canais
    ├── MULTI-AGENT.md         # Múltiplos agentes
    └── SKILLS.md              # Skills recomendados
```

## ⚠️ Antes de Começar

1. **Leia [SECURITY.md](docs/SECURITY.md)** — nunca rode OpenClaw sem hardening!
2. **PostgreSQL é essencial** — sem memória vetorial, o agente esquece tudo
3. **Proteja suas keys** — nunca commite `.env` ou `openclaw.json` real

## 🛠️ Requisitos

- macOS, Linux ou WSL2
- Node.js 18+
- PostgreSQL 14+ com pgvector
- Pelo menos 1 API key (Anthropic, OpenAI ou Google)

## 🔗 Links Úteis

- **OpenClaw oficial:** https://github.com/OpenClawAI/OpenClaw
- **Documentação:** https://docs.openclaw.ai
- **Community:** Discord / Telegram

## 📄 Licença

MIT — use, modifique e distribua livremente.

---

**Criado por Escotilha** — Ajudando desenvolvedores brasileiros a construir agentes de IA poderosos e seguros.
