# DevOpsWorkflow

Trabalhos práticos da disciplina de **DevOps** — UFLA.

Aplicação Node.js + Express com um endpoint HTTP `GET /hello`, containerizada com Docker e
publicada automaticamente no **GitHub Container Registry (GHCR)** por uma pipeline de
GitHub Actions que inclui verificações automatizadas de segurança (DevSecOps).

- **Repositório:** https://github.com/MilitaoPedro/DevOpsWorkflow
- **Imagem publicada:** `ghcr.io/militaopedro/devopsworkflow`
- **Tags disponíveis:** `1.0` (Hello World) e `2.0` (Hello World 2)

---

# Parte 1 — Trabalho Prático: Pipeline DevSecOps com GitHub Actions

## Ferramentas integradas

| Requisito | Ferramenta | Arquivo / Job | Bloqueante |
| --------- | ---------- | ------------- | ---------- |
| 1 — Detecção de segredos | **Gitleaks** | job `gitleaks` · `.gitleaks.toml` | ✅ sim |
| 2 — Análise estática (SAST) | **SonarCloud** | job `sonarcloud` · `sonar-project.properties` | ✅ sim (Quality Gate) |
| 3 — Dependências e imagem | **Trivy** | job `trivy` | ✅ CRITICAL/HIGH com correção |
| 4 — SBOM | **Syft** | job `sbom` | artifact da execução |

Arquivo da pipeline: [`.github/workflows/security.yml`](.github/workflows/security.yml)

## Quando as verificações executam

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main]
  push:
    branches: [main]
```

As verificações rodam automaticamente na **abertura e atualização de Pull Requests** e em
pushes para a `main`.

## Regras de bloqueio

| Verificação | Bloqueia quando | Não bloqueia quando |
| ----------- | --------------- | ------------------- |
| **Gitleaks** | encontra senha, token ou chave no histórico | — |
| **SonarCloud** | o Quality Gate de **código novo** falha | — |
| **Trivy (deps)** | CRITICAL ou HIGH **com correção disponível** | LOW e MEDIUM (vão para relatório) |
| **Trivy (imagem)** | CRITICAL ou HIGH **com correção disponível** | LOW e MEDIUM (vão para relatório) |

O Trivy usa `--ignore-unfixed`, ou seja, bloqueia apenas vulnerabilidades que já possuem
correção — exatamente como pede o enunciado. Os achados LOW/MEDIUM são publicados como
artifact (`trivy-reports`), sem interromper a execução.

### A publicação da imagem depende das verificações

O job `publish` só executa se Gitleaks, SonarCloud e Trivy passarem:

```yaml
publish:
  needs: [gitleaks, sonarcloud, trivy]
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

Se qualquer verificação obrigatória falhar, o job não roda e **a imagem não é publicada**
no registry.

## Requisito 1 — Gitleaks

Varredura do **histórico completo** do repositório (`fetch-depth: 0`), falhando quando
identifica um possível vazamento.

```yaml
- uses: gitleaks/gitleaks-action@e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e # v3.0.0
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITLEAKS_CONFIG: .gitleaks.toml
```

O `.gitleaks.toml` usa `[extend] useDefault = true`, ou seja, **mantém todas as regras
padrão** do Gitleaks e apenas exclui caminhos que comprovadamente não contêm segredos
(o próprio arquivo de config, `evidence/` e os PDFs de enunciado). Nenhuma regra de
detecção foi desativada.

> **Licença:** a `GITLEAKS_LICENSE` é exigida apenas para contas de **organização**.
> Como `MilitaoPedro` é uma conta pessoal, nenhuma licença é necessária.

## Requisito 2 — SonarCloud

```yaml
- uses: SonarSource/sonarqube-scan-action@4d1dc0c91ee400dcf8a6dddf2f705ac36542e304 # v8.4.0
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  with:
    args: >
      -Dsonar.qualitygate.wait=true
```

`sonar.qualitygate.wait=true` faz o scanner **aguardar** o resultado do Quality Gate e
retornar erro quando ele falhar — é isso que efetivamente bloqueia o merge. O Quality Gate
padrão ("Sonar way") avalia o **código novo**, atendendo ao pedido de gate voltado a New
Code.

### Configuração (SonarCloud)

O projeto está configurado com:

```properties
sonar.organization=militao-experiments
sonar.projectKey=militao-experiments_devopsworkflow
sonar.qualitygate.wait=true
```

O token fica **apenas** no secret `SONAR_TOKEN` do repositório
(**Settings → Secrets and variables → Actions**), nunca no arquivo de configuração — é
justamente o que o Requisito 1 (Gitleaks) verifica.

## Requisito 3 — Trivy

Quatro varreduras, duas bloqueantes e duas apenas de relatório:

| Alvo | Severidade | `exit-code` | Efeito |
| ---- | ---------- | ----------- | ------ |
| dependências (`fs`) | CRITICAL,HIGH | `1` | **bloqueia** |
| dependências (`fs`) | LOW,MEDIUM | `0` | relatório |
| imagem (`image`) | CRITICAL,HIGH | `1` | **bloqueia** |
| imagem (`image`) | LOW,MEDIUM | `0` | relatório |

### Endurecimento da imagem (correção aplicada)

A varredura inicial da imagem encontrou **1 CRITICAL e 26 HIGH**, todas vindas do **npm
empacotado na imagem base** (`tar`, `pacote`, `sigstore`, `glob`, `minimatch`,
`cross-spawn`…) e **nenhuma** do código da aplicação — verifiquei que nenhum desses pacotes
está na árvore de dependências do projeto.

O `Dockerfile` foi corrigido em vez de se silenciarem os achados:

- build em **dois estágios**, com o `npm ci` rodando apenas no estágio `builder`;
- remoção do **npm/corepack** da imagem final (a aplicação só precisa de `node app.js`);
- `apk upgrade --no-cache` para aplicar as correções do Alpine.

Resultado medido:

| Imagem | CRITICAL | HIGH |
| ------ | -------- | ---- |
| antes (`node:20-alpine` + npm) | 1 | 26 |
| **depois (Dockerfile endurecido)** | **0** | **0** |

O endpoint continua respondendo `Hello World 2` após o endurecimento.

## Requisito 4 — Syft (SBOM)

Gera o SBOM da imagem Docker em **dois formatos** e publica como artifact:

- `sbom-image.cdx.json` — CycloneDX 1.7
- `sbom-image.spdx.json` — SPDX 2.3

```yaml
- uses: anchore/sbom-action@66cbf4bc1f1c0d2edc94016e65bc221b6bb0ad6c # v0.24.3
  with:
    image: devopsworkflow:sbom
    format: cyclonedx-json
    output-file: sbom-image.cdx.json
    upload-artifact: false
```

O SBOM lista os componentes e suas versões (242 componentes no CycloneDX, 90 pacotes no
SPDX) e fica disponível em **Actions → execução → Artifacts → `sbom-image`**.

## Requisito 5 — Demonstração do bloqueio e da correção

Passo a passo completo em [`evidence/`](evidence/) e detalhado na seção
[Evidências](#evidências-devsecops). Resumo do procedimento:

1. Em uma branch de teste, adicionar uma dependência com CVE conhecida e correção
   disponível — usei `minimist@1.2.0` (CRITICAL) e `lodash@4.17.15` + `axios@0.21.1` (HIGH).
2. Abrir Pull Request para `main`.
3. Comprovar a falha do job `trivy` e o **bloqueio do merge**.
4. Corrigir as versões e comprovar a execução bem-sucedida.
5. A versão vulnerável **nunca é publicada no registry** (o job `publish` depende do Trivy).

### Configuração da proteção de branch (obrigatória para o bloqueio real)

Sem proteção de branch o GitHub mostra o check vermelho, mas ainda permite o merge. Para
exigir os checks de segurança na `main`:

```bash
gh auth login   # se ainda não estiver autenticado

gh api -X PUT repos/MilitaoPedro/DevOpsWorkflow/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["gitleaks", "sonarcloud", "trivy", "sbom"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
JSON
```

Alternativa pela interface: **Settings → Branches → Add branch protection rule**, marcar
*Require status checks to pass before merging* e selecionar `gitleaks`, `sonarcloud`,
`trivy` e `sbom`.

Para conferir depois:

```bash
gh api repos/MilitaoPedro/DevOpsWorkflow/branches/main/protection \
  --jq '.required_status_checks.contexts'
```

---

# Parte 2 — Exercício prático: Docker, GitHub Actions e Container Registry

## Estrutura do projeto

```
.
├── .github/workflows/security.yml  # pipeline DevSecOps (build, testes, segurança, push)
├── .gitleaks.toml                  # configuração do Gitleaks
├── sonar-project.properties        # configuração do SonarCloud
├── Dockerfile                      # imagem da aplicação (multi-stage, endurecida)
├── app.js                          # aplicação Express (endpoint /hello)
├── package.json                    # dependências
├── package-lock.json               # versões travadas (usado pelo `npm ci`)
├── VERSION                         # tag da imagem publicada pela pipeline
├── .dockerignore
├── evidence/                       # evidências de execução
└── README.md
```

## Aplicação

`app.js` sobe um servidor Express na porta `8080` com o endpoint `GET /hello`:

```js
app.get('/hello', (req, res) => {
  res.type('text/plain').send(MESSAGE);
});
```

| Versão | Resposta do endpoint |
| ------ | -------------------- |
| 1.0    | `Hello World`        |
| 2.0    | `Hello World 2`      |

## Dockerfile

Build em dois estágios: as dependências são instaladas no estágio `builder` e a imagem
final recebe apenas o necessário para executar, como usuário não privilegiado.

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS runtime
RUN apk upgrade --no-cache
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm /usr/local/bin/npx
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY package.json app.js ./
USER node
EXPOSE 8080
CMD ["node", "app.js"]
```

Build local:

```bash
docker build -t minha-aplicacao:1.0 .
```

## Validação local

```bash
docker run -p 8080:8080 minha-aplicacao:1.0
curl http://localhost:8080/hello
# Hello World
```

## Pipeline

| Etapa | O que faz |
| ----- | --------- |
| **Disparo** | `on: push` na `main`, `pull_request` para `main` e `workflow_dispatch` |
| **gitleaks** | varredura de segredos no histórico |
| **sonarcloud** | análise estática + Quality Gate |
| **trivy** | varredura de dependências e da imagem (bloqueante CRITICAL/HIGH) |
| **sbom** | gera e publica o SBOM da imagem |
| **publish** | build, teste do container e push para o GHCR (só se os gates passarem) |

### Credenciais

As credenciais **não ficam escritas na pipeline**. O login no registry usa o `GITHUB_TOKEN`
fornecido pelo GitHub Actions:

```yaml
- name: Login no GitHub Container Registry
  uses: docker/login-action@81c6f93d4bc991e510b342a00b419b3bb4efc5c6 # v4.7.0
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

Para outro registry (ex.: Docker Hub), basta trocar por secrets próprios:

```yaml
    username: ${{ secrets.REGISTRY_USERNAME }}
    password: ${{ secrets.REGISTRY_TOKEN }}
```

### Versionamento

A tag vem do arquivo `VERSION` na raiz. Para publicar uma nova versão, altere o conteúdo do
arquivo e faça o push.

### Actions fixadas por SHA

Todas as actions de terceiros estão fixadas pelo **commit SHA** (com a versão em
comentário), e não por tag móvel — assim uma tag reescrita não consegue introduzir código
novo no pipeline:

```yaml
uses: aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25 # v0.36.0
```

## Imagem no registry

```bash
docker pull ghcr.io/militaopedro/devopsworkflow:1.0
docker run -p 8080:8080 ghcr.io/militaopedro/devopsworkflow:1.0
curl http://localhost:8080/hello
# Hello World
```

## Fluxo completo

```
Desenvolvedor → git push → Repositório GitHub
  → GitHub Actions → Build da aplicação/imagem
  → Push para Container Registry
  → docker pull → Execução local → Teste do endpoint
```

---

# Evidências DevSecOps

| Entregável | Arquivo |
| ---------- | ------- |
| Pipeline com as ferramentas integradas | [`evidence/devsecops-pipeline.md`](evidence/devsecops-pipeline.md) |
| PR bloqueado + relatório da vulnerabilidade | [`evidence/devsecops-bloqueio.md`](evidence/devsecops-bloqueio.md) |
| Execução aprovada após a correção | [`evidence/devsecops-correcao.md`](evidence/devsecops-correcao.md) |
| SBOM publicado como artifact | [`evidence/devsecops-sbom.md`](evidence/devsecops-sbom.md) |

# Evidências — Parte 2

| Entregável | Arquivo |
| ---------- | ------- |
| Build e execução local da versão 1.0 | [`evidence/local-1.0.md`](evidence/local-1.0.md) |
| Build e execução local da versão 2.0 | [`evidence/local-2.0.md`](evidence/local-2.0.md) |
| Imagem 1.0 publicada e executada do registry | [`evidence/registry-1.0.md`](evidence/registry-1.0.md) |
| Imagem 2.0 publicada e executada do registry | [`evidence/registry-2.0.md`](evidence/registry-2.0.md) |
| Execução final das duas tags do registry | [`evidence/validacao-final.md`](evidence/validacao-final.md) |
| Execuções da pipeline | [run 1.0](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40615501744) · [run 2.0](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40616143584) |
