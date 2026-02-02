# 🚀 OpenClaw Starter Kit

> **Setup OpenClaw pronto para produção com memória PostgreSQL, hardening de segurança e configurações otimizadas para desenvolvedores brasileiros.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Português](https://img.shields.io/badge/Língua-Português-green.svg)](README.md)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-blue.svg)](https://www.postgresql.org/)
[![pgvector](https://img.shields.io/badge/pgvector-0.8+-purple.svg)](https://github.com/pgvector/pgvector)

Baseado em **deployments reais** rodando múltiplos agentes através de WhatsApp, Slack, Telegram e Discord. Este é um guia prático e opinativo para colocar OpenClaw em produção com segurança enterprise.

---

## ✨ Destaques

- 🧠 **Memória Persistente PostgreSQL** - Setup completo com pgvector para embeddings vetoriais
- 🔐 **Segurança Enterprise** - 12 domínios de hardening de segurança documentados
- 📱 **Multi-Canal** - WhatsApp, Slack, Telegram, Discord configurados
- 🤖 **Multi-Agent** - Template para rodar 2-3 agentes especializados
- 🇧🇷 **Em Português** - Toda documentação em PT-BR para devs brasileiros
- ⚡ **Scripts Automatizados** - Setup PostgreSQL e health check com um comando

---

## 🚀 Início Rápido

```bash
# 1. Instalar OpenClaw
npm install -g openclaw

# 2. Clonar este repositório
git clone https://github.com/escotilha/openclaw-starter.git
cd openclaw-starter

# 3. Configurar PostgreSQL + memória (recomendado)
./scripts/setup-postgres.sh

# 4. Copiar template de configuração
cp templates/single-agent.json ~/.openclaw/openclaw.json

# 5. Configurar suas API keys
cp templates/.env.example ~/.openclaw/.env
# Edite ~/.openclaw/.env com suas keys reais

# 6. Verificar instalação
./scripts/health-check.sh

# 7. Iniciar OpenClaw
openclaw gateway start
```

---

## 📚 Documentação Completa

| 📖 Guia | 📝 Descrição | ⏱️ Tempo |
|---------|--------------|----------|
| **[INSTALL.md](docs/INSTALL.md)** | Instalação e configuração inicial | 15 min |
| **[MEMORY.md](docs/MEMORY.md)** ⭐ | Setup PostgreSQL + pgvector para memória persistente | 20 min |
| **[SECURITY.md](docs/SECURITY.md)** ⭐ | 12 domínios de hardening de segurança | 30 min |
| **[MULTI-AGENT.md](docs/MULTI-AGENT.md)** | Rodando múltiplos agentes especializados | 25 min |
| **[CHANNELS.md](docs/CHANNELS.md)** | Configuração WhatsApp, Slack, Telegram, Discord | 20 min |
| **[SKILLS.md](docs/SKILLS.md)** | Skills essenciais e plugins | 15 min |

---

## 🎯 O Que Está Incluído

### 🔥 Prioridade 1: Memória PostgreSQL

Guia completo para configurar memória persistente enterprise-grade:

- ✅ Instalação PostgreSQL + pgvector via Homebrew
- ✅ Schema otimizado para busca semântica vetorial
- ✅ Configuração embeddings OpenAI (text-embedding-3-small)
- ✅ Troubleshooting e otimização de performance
- ✅ Estratégias de backup e restore

### 🛡️ Prioridade 2: Hardening de Segurança

12 domínios de segurança documentados:

1. 🔴 **Exposição do Gateway** - Binding loopback + auth token
2. 🟠 **Política de DMs** - Pairing vs allowlist
3. 🟠 **Controle de Grupos** - Allowlist de canais
4. 🔴 **Segurança de Credenciais** - Variáveis de ambiente
5. 🟠 **Binding de Rede** - Tailscale para acesso remoto
6. 🟡 **Limites de Mídia** - Rate limiting e debounce
7. 🟠 **Tokens Read-Only** - Slack user tokens seguros
8. 🟡 **Permissões de Arquivo** - chmod 700/600
9. 🟡 **Logging & Redação** - Redact sensitive data
10. 🔴 **Segurança do Banco** - SSL + passwords
11. 🟡 **Prompt Injection** - Proteção contra ataques
12. 🟡 **Backup & Recovery** - Automated backups

### 📦 Prioridade 3: Templates Prontos

- **single-agent.json** - Setup minimalista para 1 agente
- **multi-agent.json** - Configuração para 2-3 agentes especializados
- **.env.example** - Template completo de variáveis de ambiente
- Todos com **placeholders sanitizados** (zero credenciais reais)

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                  OpenClaw Gateway                        │
│            (127.0.0.1:18789 + token auth)               │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │ Agent 1 │       │ Agent 2 │       │ Agent N │
   │  main   │       │  work   │       │  tech   │
   │ Opus 4.5│       │Sonnet4.5│       │ GPT-4o  │
   └─────────┘       └─────────┘       └─────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                   ┌───────────────┐
                   │  PostgreSQL   │
                   │  + pgvector   │
                   │  (embeddings) │
                   └───────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │  WhatsApp, Slack,       │
              │  Telegram, Discord      │
              └─────────────────────────┘
```

---

## 🛠️ Scripts Utilitários

| 📜 Script | 🎯 Propósito | ⚡ Uso |
|-----------|--------------|--------|
| `setup-postgres.sh` | Instalação automatizada PostgreSQL + pgvector | `./scripts/setup-postgres.sh` |
| `health-check.sh` | Verificar instalação e configuração OpenClaw | `./scripts/health-check.sh` |

---

## 🔐 Segurança em Primeiro Lugar

Este guia enfatiza segurança desde o dia zero:

| ✅ Configuração Segura | ❌ Evite |
|------------------------|----------|
| Gateway em `loopback` | Gateway em `0.0.0.0` |
| Auth token 32+ chars | Sem auth token |
| DM: `pairing`/`allowlist` | DM: `open` |
| Grupos: `allowlist` | Grupos: `open` |
| Credenciais em `.env` | Credenciais no config |
| `chmod 600` em configs | Permissões soltas |

**⚠️ Nunca faça commit de API keys reais!** Use variáveis de ambiente.

---

## 💡 Casos de Uso

### 👨‍💼 Assistente Pessoal + Trabalho

```bash
# Use multi-agent.json
cp templates/multi-agent.json ~/.openclaw/openclaw.json
```

- **Agent "main"**: Vida pessoal (WhatsApp pessoal, calendário)
- **Agent "work"**: Trabalho (Slack empresa, email corporativo)
- **Agent "tech"**: Suporte técnico (Discord, GitHub)

### 🏢 Operações Business

- Monitora métricas e KPIs
- Coordena time no Slack
- Gera relatórios automatizados
- Rastreia pipeline de vendas

### 👨‍💻 Desenvolvedor

- Code reviews automatizados
- CI/CD monitoring
- GitHub automation
- Documentation generation

---

## 📊 Custos Estimados

### Embeddings (Memória)
- **text-embedding-3-small**: $0.02 / 1M tokens
- **1000 memórias**: ~$0.001 (praticamente grátis)

### Modelos
- **Claude Opus 4.5**: $3 input / $15 output (MTok)
- **Claude Sonnet 4.5**: $3 input / $15 output (MTok)
- **Claude Haiku 4**: $0.25 input / $1.25 output (MTok)
- **GPT-4o**: $2.50 input / $10 output (MTok)

### Infraestrutura
- **PostgreSQL local**: Grátis
- **AWS RDS db.t3.micro**: ~$15/mês
- **DigitalOcean 1GB**: ~$15/mês

---

## 🤝 Contribuindo

Encontrou um problema ou quer melhorar os guias? 

1. Fork o repositório
2. Crie uma branch (`git checkout -b feature/melhoria`)
3. Commit suas mudanças (`git commit -am 'Adiciona melhoria X'`)
4. Push para a branch (`git push origin feature/melhoria`)
5. Abra um Pull Request

---

## 📄 Licença

[MIT License](LICENSE) - livre para usar, modificar e distribuir.

---

## 🔗 Recursos

- 📖 **Docs Oficiais**: https://docs.openclaw.ai
- 💻 **GitHub OpenClaw**: https://github.com/openclaw/openclaw
- 💬 **Discord**: [OpenClaw Community](https://discord.gg/openclaw)
- 🐛 **Issues**: [Reportar Problemas](https://github.com/escotilha/openclaw-starter/issues)

---

## ⚠️ Avisos Importantes

1. **Starter kit não-oficial** - Criado pela comunidade brasileira, não pela equipe OpenClaw
2. **Sempre revise configs** antes de fazer deploy em produção
3. **Rotacione credenciais** regularmente (mínimo 90 dias)
4. **Faça backup do banco** - Memória é preciosa!
5. **Teste em dev** antes de aplicar em produção

---

## 🌟 Por Que Este Starter Kit?

- ✅ **Português BR nativo** - Sem traduções automáticas ruins
- ✅ **Baseado em produção real** - Não é teoria, é prática
- ✅ **Segurança first** - 12 domínios de hardening documentados
- ✅ **PostgreSQL enterprise** - Não fique preso ao LanceDB
- ✅ **Scripts prontos** - Setup em minutos, não horas
- ✅ **Multi-agent** - Templates para casos de uso reais
- ✅ **Mantido ativamente** - Updates regulares com novos recursos

---

## 🎓 Próximos Passos

1. ⚡ **[Instale OpenClaw](docs/INSTALL.md)** - 15 minutos
2. 🧠 **[Configure Memória PostgreSQL](docs/MEMORY.md)** - 20 minutos
3. 🔐 **[Aplique Hardening de Segurança](docs/SECURITY.md)** - 30 minutos
4. 📱 **[Configure Canais](docs/CHANNELS.md)** - 20 minutos por canal
5. 🚀 **Deploy em Produção** - Você está pronto!

---

<div align="center">

**Construído com ❤️ pela comunidade OpenClaw brasileira**

[⭐ Star este repo](https://github.com/escotilha/openclaw-starter) | [🐛 Reportar Bug](https://github.com/escotilha/openclaw-starter/issues) | [💡 Sugerir Feature](https://github.com/escotilha/openclaw-starter/issues)

</div>
