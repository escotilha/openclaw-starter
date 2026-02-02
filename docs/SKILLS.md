# Guia de Skills & Plugins

**Skills e plugins recomendados para extender capacidades do OpenClaw.**

## O Que São Skills?

Skills são pacotes instaláveis que adicionam novas capacidades aos agentes OpenClaw.

## Instalando Skills

```bash
# Buscar skills
openclaw skill search <palavra-chave>

# Instalar skill
openclaw skill install <nome-skill>

# Listar instalados
openclaw skill list

# Remover skill
openclaw skill remove <nome-skill>
```

## Skills Essenciais

### 1. Security Scanner

**Propósito**: Auditar configuração OpenClaw

```bash
openclaw skill install openclaw-security-scanner

# Rodar auditoria
openclaw scan security

# Auto-fix
openclaw scan security --fix
```

### 2. Calendar Integration

**Propósito**: Integração Google Calendar, Outlook, iCal

```bash
openclaw skill install calendar-sync
```

### 3. Email Management

**Propósito**: Ler e enviar emails

```bash
openclaw skill install email-tools
```

### 4. Voice & Audio

**Propósito**: Text-to-speech e speech-to-text

```bash
openclaw skill install sag  # ElevenLabs TTS
```

**Configuração**:
```json
{
  "skills": {
    "entries": {
      "sag": {
        "apiKey": "${ELEVENLABS_API_KEY}",
        "voiceId": "21m00Tcm4TlvDq8ikWAM"
      }
    }
  }
}
```

### 5. Code Assistant

**Propósito**: Integração GitHub, code review

```bash
openclaw skill install code-assistant
```

## Configuração de Skills

### Config Global

```json
{
  "skills": {
    "install": {
      "nodeManager": "npm"
    },
    "entries": {
      "nome-skill": {
        "enabled": true,
        "config": {
          "key": "valor"
        }
      }
    }
  }
}
```

### Skills por Agente

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "skills": {
          "enabled": ["calendar-sync", "email-tools"]
        }
      },
      {
        "id": "tech",
        "skills": {
          "enabled": ["code-assistant"]
        }
      }
    ]
  }
}
```

## Configuração de Plugins

Plugins são integrações mais profundas que skills.

### Plugins Disponíveis

| Plugin | Propósito | Slot |
|--------|-----------|------|
| `memory-postgres` | Backend PostgreSQL | `memory` |
| `memory-lancedb` | Backend LanceDB | `memory` |
| `whatsapp` | Canal WhatsApp | `channel` |
| `slack` | Canal Slack | `channel` |

### Slots de Plugin

Apenas um plugin por slot:

```json
{
  "plugins": {
    "slots": {
      "memory": "memory-postgres"
    },
    "entries": {
      "memory-postgres": {
        "enabled": true
      },
      "memory-lancedb": {
        "enabled": false
      }
    }
  }
}
```

## Combinações Recomendadas

### Setup Assistente Pessoal
```bash
openclaw skill install calendar-sync
openclaw skill install email-tools
openclaw skill install sag
```

### Setup Operações Business
```bash
openclaw skill install task-manager
openclaw skill install doc-processor
openclaw skill install code-assistant
```

### Setup Desenvolvedor
```bash
openclaw skill install code-assistant
openclaw skill install web-tools
openclaw skill install system-tools
```

---

**Próximo**: Explore o [marketplace de skills](https://skills.openclaw.ai) (se disponível).
