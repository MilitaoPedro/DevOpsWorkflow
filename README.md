# DevOpsWorkflow

Exercício prático de **Docker, GitHub Actions e Container Registry**.

Aplicação Node.js + Express com um endpoint HTTP `GET /hello`, containerizada com Docker e
publicada automaticamente no **GitHub Container Registry (GHCR)** por uma pipeline de
GitHub Actions disparada a cada push na branch `main`.

- **Repositório:** https://github.com/MilitaoPedro/DevOpsWorkflow
- **Imagem publicada:** `ghcr.io/militaopedro/devopsworkflow`
- **Tags disponíveis:** `1.0` (Hello World) e `2.0` (Hello World 2)

---

## Estrutura do projeto

```
.
├── .github/workflows/docker.yml   # pipeline de CI/CD
├── Dockerfile                     # imagem da aplicação
├── app.js                         # aplicação Express (endpoint /hello)
├── package.json                   # dependências
├── package-lock.json              # versões travadas (usado pelo `npm ci`)
├── VERSION                        # tag da imagem a ser publicada pela pipeline
├── .dockerignore
├── evidence/                      # evidências de execução
└── README.md
```

## 1. Aplicação

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

## 2. Dockerfile

O `Dockerfile` usa `node:20-alpine`, instala as dependências com `npm ci --omit=dev` e
executa a aplicação como o usuário não privilegiado `node`.

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY app.js ./
USER node
EXPOSE 8080
CMD ["node", "app.js"]
```

Build local:

```bash
docker build -t minha-aplicacao:1.0 .
```

## 3. Validação local

```bash
docker run -p 8080:8080 minha-aplicacao:1.0
curl http://localhost:8080/hello
# Hello World
```

Evidências em [`evidence/local-1.0.md`](evidence/local-1.0.md) e
[`evidence/local-2.0.md`](evidence/local-2.0.md).

## 4. Pipeline (GitHub Actions)

Arquivo: [`.github/workflows/docker.yml`](.github/workflows/docker.yml)

Fluxo executado: `Código → Build → Imagem Docker → Push para Registry`

| Etapa | O que faz |
| ----- | --------- |
| **Disparo** | `on: push` nas branches `main` (e `workflow_dispatch` manual) |
| **Checkout** | `actions/checkout@v4` baixa o código do repositório |
| **Tag** | Lê o arquivo `VERSION` e define a tag da imagem |
| **Build** | `docker/build-push-action@v6` constrói a imagem |
| **Verificação** | `docker image inspect` confirma que a imagem foi criada |
| **Teste** | Sobe o container e valida `GET /hello` antes do push |
| **Login** | `docker/login-action@v3` autentica no `ghcr.io` |
| **Push** | Publica `ghcr.io/militaopedro/devopsworkflow:<VERSION>` |

### Credenciais

As credenciais **não ficam escritas no arquivo da pipeline**. O login no registry usa o
`GITHUB_TOKEN` fornecido automaticamente pelo GitHub Actions, lido via o mecanismo de
Secrets:

```yaml
- name: Login no GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

Para publicar em outro registry (ex.: Docker Hub), basta trocar por secrets próprios, sem
alterar o restante do fluxo:

```yaml
    username: ${{ secrets.REGISTRY_USERNAME }}
    password: ${{ secrets.REGISTRY_TOKEN }}
```

### Versionamento

A tag da imagem vem do arquivo `VERSION` na raiz. Para publicar uma nova versão, altere o
conteúdo do arquivo e faça o push — a pipeline gera e publica a nova tag automaticamente.

## 5. Imagem no registry

```bash
docker pull ghcr.io/militaopedro/devopsworkflow:1.0
docker run -p 8080:8080 ghcr.io/militaopedro/devopsworkflow:1.0
curl http://localhost:8080/hello
# Hello World
```

Evidências em [`evidence/registry-1.0.md`](evidence/registry-1.0.md) e
[`evidence/registry-2.0.md`](evidence/registry-2.0.md).

## 6. Fluxo completo

```
Desenvolvedor → git push → Repositório GitHub
  → GitHub Actions → Build da aplicação/imagem
  → Push para Container Registry
  → docker pull → Execução local → Teste do endpoint
```
