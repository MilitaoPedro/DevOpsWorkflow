# Evidência — pipeline DevSecOps com as ferramentas integradas

**Execução:** [run #40623709633](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40623709633)
**Commit:** `c2eedf6` · **Branch:** `main` · **Resultado:** ✅ success

## Jobs e resultado

| Job | Ferramenta | Resultado |
| --- | ---------- | --------- |
| `gitleaks` | Gitleaks | ✅ success |
| `sonarcloud` | SonarCloud | ✅ success |
| `trivy` | Trivy | ✅ success |
| `sbom` | Syft | ✅ success |
| `publish` | Docker / GHCR | ✅ success |

```
JOB gitleaks       -> success
    [ok ] Checkout do codigo (historico completo)
    [ok ] Varredura de segredos com Gitleaks
JOB sonarcloud     -> success
    [ok ] Checkout do codigo (historico completo)
    [ok ] Analise SonarCloud
JOB trivy          -> success
    [ok ] Trivy - dependencias (bloqueia CRITICAL/HIGH com correcao)
    [ok ] Trivy - dependencias (relatorio LOW/MEDIUM, nao bloqueia)
    [ok ] Build da imagem Docker para varredura
    [ok ] Trivy - imagem (bloqueia CRITICAL/HIGH com correcao)
    [ok ] Trivy - imagem (relatorio LOW/MEDIUM, nao bloqueia)
    [ok ] Publicar relatorios do Trivy
JOB sbom           -> success
    [ok ] Build da imagem Docker para o SBOM
    [ok ] Gerar SBOM com Syft (CycloneDX)
    [ok ] Gerar SBOM com Syft (SPDX)
    [ok ] Publicar SBOM como artifact
JOB publish        -> success
    [ok ] Build da imagem Docker
    [ok ] Testar o container antes do push
    [ok ] Push da imagem para o registry
```

Observação: o job `publish` depende de `[gitleaks, sonarcloud, trivy]`. Ele só apareceu
porque as três verificações de segurança passaram.

## Artifacts publicados na execução

| Artifact | Tamanho | Origem |
| -------- | ------- | ------ |
| `sbom-image` | 58.715 bytes | Syft (CycloneDX + SPDX) — Requisito 4 |
| `trivy-reports` | 2.918 bytes | Trivy (relatórios LOW/MEDIUM) |
| `gitleaks-results.sarif` | 6.788 bytes | Gitleaks |

## Varredura da imagem endurecida

O `Dockerfile` foi corrigido para eliminar as vulnerabilidades herdadas da imagem base.
Comparação medida com o mesmo comando do pipeline:

```bash
trivy image --scanners vuln --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1
```

| Imagem | CRITICAL | HIGH | Gate |
| ------ | -------- | ---- | ---- |
| antes (`node:20-alpine` com npm) | 1 | 26 | ❌ falha |
| **depois (Dockerfile multi-stage)** | **0** | **0** | ✅ passa |

As 27 vulnerabilidades vinham do **npm empacotado na imagem base** (`tar`, `pacote`,
`sigstore`, `glob`, `minimatch`, `cross-spawn`…). Nenhuma delas pertence à árvore de
dependências da aplicação — confirmado com a varredura das dependências do projeto, que
retorna `0` achados em `package-lock.json`.

Correção aplicada (sem desativar nenhum gate):

1. build em dois estágios, com `npm ci` apenas no estágio `builder`;
2. remoção do `npm`/`corepack` da imagem final;
3. `apk upgrade --no-cache` para aplicar as correções do Alpine.

O endpoint continua respondendo corretamente após o endurecimento (`Hello World 2`).
