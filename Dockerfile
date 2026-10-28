# ---------------------------------------------------------------------------
# Estagio 1 (builder): instala as dependencias de producao.
# O npm existe apenas neste estagio e NAO e copiado para a imagem final.
# ---------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copia primeiro os manifestos para aproveitar o cache de camadas do Docker:
# a instalacao das dependencias so roda de novo quando package.json muda.
COPY package*.json ./

# "npm ci" faz uma instalacao limpa e reproduzivel a partir do lock file.
RUN npm ci --omit=dev

# ---------------------------------------------------------------------------
# Estagio 2 (runtime): imagem final, minima.
# ---------------------------------------------------------------------------
FROM node:20-alpine AS runtime

# Aplica as correcoes de seguranca disponiveis para os pacotes do Alpine.
RUN apk upgrade --no-cache

# Remove o npm e o corepack da imagem final.
#
# Eles nao sao necessarios para executar a aplicacao (apenas "node app.js") e
# sao a origem da maior parte das vulnerabilidades CRITICAL/HIGH apontadas pelo
# Trivy (tar, pacote, sigstore, glob, minimatch, cross-spawn...), que vem
# empacotadas dentro do proprio npm da imagem base - e nao do codigo da
# aplicacao. Sem eles a imagem fica com 0 CRITICAL e 0 HIGH.
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm \
           /usr/local/bin/npx

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY app.js ./

# Executa como usuario nao privilegiado (a imagem node ja fornece o usuario "node").
USER node

EXPOSE 8080

CMD ["node", "app.js"]
