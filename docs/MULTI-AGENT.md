# Guia de Setup Multi-Agent

**Rodando múltiplos agentes especializados em uma instância OpenClaw.**

## Por Que Múltiplos Agentes?

### Benefícios

- ✅ **Especialização**: Cada agente tem domínio claro
- ✅ **Workspaces isolados**: Arquivos e memórias separadas
- ✅ **Processamento paralelo**: Múltiplas tarefas simultâneas
- ✅ **Personalidades distintas**: Tom/estilo diferente por agente
- ✅ **Melhor segurança**: Privilégio mínimo por agente

## Arquitetura

```
Gateway (localhost:18789)
├── main (Pessoal) - Assistente pessoal
│   ├── Workspace: ~/.openclaw/workspace-main
│   ├── Model: claude-opus-4-5
│   └── Channels: WhatsApp (pessoal), Email
│
├── work (Trabalho) - Operações business
│   ├── Workspace: ~/.openclaw/workspace-work
│   ├── Model: claude-sonnet-4-5
│   └── Channels: Slack (empresa), Email (work@)
│
└── tech (Técnico) - Assistente técnico
    ├── Workspace: ~/.openclaw/workspace-tech
    ├── Model: gpt-4o
    └── Channels: Discord, GitHub
```

## Configuração

### Setup Básico Multi-Agent

```json
{
  "agents": {
    "defaults": {
      "workspace": "/Users/seunome/.openclaw/workspace",
      "maxConcurrent": 2,
      "model": "anthropic/claude-sonnet-4-5",
      "subagents": {
        "maxConcurrent": 6
      }
    },
    "list": [
      {
        "id": "main",
        "model": "anthropic/claude-opus-4-5",
        "workspace": "/Users/seunome/.openclaw/workspace-main",
        "memory": {
          "shared": false,
          "namespace": "main"
        }
      },
      {
        "id": "work",
        "workspace": "/Users/seunome/.openclaw/workspace-work",
        "identity": {
          "name": "Work",
          "emoji": "📊"
        },
        "memory": {
          "shared": false,
          "namespace": "work"
        }
      },
      {
        "id": "tech",
        "workspace": "/Users/seunome/.openclaw/workspace-tech",
        "model": "openai/gpt-4o",
        "identity": {
          "name": "Tech",
          "emoji": "💻"
        },
        "memory": {
          "shared": false,
          "namespace": "tech"
        }
      }
    ]
  }
}
```

## Roteamento de Canais

### Atribuir Canais a Agentes Específicos

```json
{
  "channels": {
    "whatsapp": {
      "accounts": {
        "pessoal": {
          "agent": "main",
          "dmPolicy": "pairing"
        },
        "trabalho": {
          "agent": "work",
          "dmPolicy": "allowlist"
        }
      }
    },
    "slack": {
      "accounts": {
        "empresa": {
          "agent": "work",
          "groupPolicy": "allowlist"
        }
      }
    },
    "discord": {
      "accounts": {
        "tech": {
          "agent": "tech"
        }
      }
    }
  }
}
```

## Memória Compartilhada vs Isolada

### Memória Isolada (Padrão)

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
        "id": "work",
        "memory": {
          "shared": false,
          "namespace": "work"
        }
      }
    ]
  }
}
```

**Use quando**: Agentes têm domínios diferentes (trabalho/pessoal)

### Memória Compartilhada

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

**Use quando**: Agentes colaboram nas mesmas tarefas

## Organização de Workspace

```
~/.openclaw/
├── workspace-main/          # Agente main
│   ├── SOUL.md
│   ├── MEMORY.md
│   └── memory/
│       └── 2026-02-01.md
│
├── workspace-work/          # Agente work
│   ├── SOUL.md
│   ├── MEMORY.md
│   └── reports/
│
└── workspace-tech/          # Agente tech
    ├── SOUL.md
    ├── MEMORY.md
    └── code/
```

## Seleção de Modelo por Agente

### Otimização de Custo

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "model": "anthropic/claude-opus-4-5"  // $15/MTok - Raciocínio complexo
      },
      {
        "id": "work",
        "model": "anthropic/claude-sonnet-4-5"  // $3/MTok - Tarefas padrão
      },
      {
        "id": "tech",
        "model": "openai/gpt-4o"  // $10/MTok - Focado em código
      }
    ]
  }
}
```

## Exemplos de Configuração

### Cenário 1: Pessoal + Trabalho

```json
{
  "agents": {
    "list": [
      {
        "id": "pessoal",
        "workspace": "~/.openclaw/workspace-pessoal",
        "memory": { "namespace": "pessoal" }
      },
      {
        "id": "trabalho",
        "workspace": "~/.openclaw/workspace-trabalho",
        "memory": { "namespace": "trabalho" }
      }
    ]
  }
}
```

### Cenário 2: Time de Criação de Conteúdo

```json
{
  "agents": {
    "list": [
      {
        "id": "escritor",
        "model": "anthropic/claude-opus-4-5"
      },
      {
        "id": "editor",
        "model": "anthropic/claude-sonnet-4-5"
      },
      {
        "id": "social",
        "model": "anthropic/claude-haiku-4"
      }
    ]
  }
}
```

## Melhores Práticas

### 1. Limites Claros

Defina o que cada agente faz em `SOUL.md`:

```markdown
# work/SOUL.md

## O Que Eu Faço
✅ Operações business da empresa
✅ Rastreamento de pipeline de vendas
✅ Coordenação de time no Slack

## O Que Eu NÃO Faço
❌ Assuntos pessoais → Escalar para main
❌ Problemas técnicos → Escalar para tech
```

### 2. Comece Pequeno

1. **Semana 1**: main + work
2. **Semana 2**: Adicione agente técnico
3. **Semana 3**: Adicione social media
4. **Semana 4**: Avalie e refine

### 3. Documente Tudo

Cada agente precisa:
- `SOUL.md` - Quem eles são
- `AGENTS.md` - Como funcionam
- `USER.md` - Quem servem
- `MEMORY.md` - O que lembram

## Troubleshooting

### Problema: Agentes Conflitando

**Solução**: Aperte roteamento de canal:

```json
{
  "channels": {
    "whatsapp": {
      "accounts": {
        "pessoal": {
          "agent": "main"  // Atribua explicitamente
        }
      }
    }
  }
}
```

### Problema: Custos Altos de API

**Solução**: Use modelos mais baratos:

```json
{
  "agents": {
    "list": [
      {
        "id": "social",
        "model": "anthropic/claude-haiku-4"  // $0.25 vs $15
      }
    ]
  }
}
```

---

**Próximo**: Veja nosso [template multi-agent.json](../templates/multi-agent.json).
