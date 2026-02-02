# Contribuindo para OpenClaw Starter Kit

Obrigado por considerar contribuir! Este projeto é mantido pela comunidade brasileira de OpenClaw.

## 🌟 Como Contribuir

### Reportando Bugs

Encontrou um bug? Por favor abra uma [Issue](https://github.com/escotilha/openclaw-starter/issues) com:

- **Título claro** descrevendo o problema
- **Passos para reproduzir** o bug
- **Comportamento esperado** vs **comportamento atual**
- **Ambiente**: macOS/Linux, versão OpenClaw, versão PostgreSQL
- **Logs relevantes** (sanitize credenciais!)

### Sugerindo Melhorias

Tem uma ideia para melhorar o starter kit?

1. Verifique se já não existe uma [Issue](https://github.com/escotilha/openclaw-starter/issues) sobre isso
2. Abra uma nova Issue com tag `enhancement`
3. Descreva claramente o problema que resolve
4. Sugira a solução proposta

### Pull Requests

1. **Fork** o repositório
2. **Clone** seu fork localmente
3. **Crie uma branch** para sua feature: `git checkout -b feature/minha-feature`
4. **Faça suas mudanças** seguindo nossas diretrizes
5. **Teste** suas mudanças
6. **Commit** com mensagem descritiva
7. **Push** para seu fork: `git push origin feature/minha-feature`
8. Abra um **Pull Request**

## 📝 Diretrizes de Código

### Documentação

- **Língua**: Toda documentação deve estar em **português brasileiro**
- **Termos técnicos**: Mantenha em inglês (API keys, tokens, PostgreSQL, etc.)
- **Tom**: Direto, prático, sem fluff
- **Exemplos**: Sempre inclua exemplos práticos e copy-paste ready

### Estrutura de Markdown

```markdown
# Título Principal

Parágrafo introdutório claro e direto.

## Seção

### Subseção

- Lista com pontos claros
- Use ✅ ❌ 🔴 🟠 🟡 para indicadores visuais

\`\`\`bash
# Comandos sempre com comentários
comando --flag valor
\`\`\`

\`\`\`json
{
  "_comment": "Explique o propósito do JSON",
  "config": "valor"
}
\`\`\`
```

### Configurações JSON

- **Sempre sanitize credenciais**: Use placeholders como `"sua-api-key-aqui"`
- **Comente seções**: Use `"_comment"` para explicar
- **Valores realistas**: Use números/IDs que parecem reais mas não são

### Scripts Bash

```bash
#!/bin/bash
# Descrição clara do que o script faz

set -e  # Sair em erro

# Comentários antes de comandos não-óbvios
comando_complexo --flag
```

## 🎯 Áreas Que Precisam de Ajuda

- [ ] Guia de instalação para Linux (Ubuntu, Debian, Arch)
- [ ] Testes automatizados dos scripts
- [ ] Exemplos de skills customizados
- [ ] Troubleshooting de casos específicos
- [ ] Integração com mais canais (iMessage, RCS)
- [ ] Docker/docker-compose setup
- [ ] CI/CD com GitHub Actions

## 🔍 Review Process

Todos os PRs passam por review antes de merge:

1. **Verificação automática** (se configurado)
2. **Review de código** por mantenedores
3. **Teste manual** em ambiente local
4. **Merge** para `main`

## 💬 Comunicação

- **Issues**: Para bugs, features, discussões
- **Pull Requests**: Para código/documentação
- **Discord OpenClaw**: Para dúvidas rápidas (não bugs)

## 📜 Código de Conduta

- Seja respeitoso e profissional
- Ajude outros membros da comunidade
- Aceite feedback construtivo
- Foque em melhorar o projeto

## ✅ Checklist de PR

Antes de submeter seu PR, verifique:

- [ ] Documentação em português brasileiro
- [ ] Exemplos práticos incluídos
- [ ] Nenhuma credencial real exposta
- [ ] Scripts testados localmente
- [ ] JSON válido (use `jq` para validar)
- [ ] Links funcionando
- [ ] Markdown formatado corretamente
- [ ] Commit message descritivo

## 🙏 Agradecimentos

Obrigado por tornar OpenClaw mais acessível para a comunidade brasileira!

---

**Dúvidas?** Abra uma [Issue](https://github.com/escotilha/openclaw-starter/issues) ou pergunte no Discord.
