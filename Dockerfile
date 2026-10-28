FROM node:20-alpine

WORKDIR /app

# Copia primeiro os manifestos para aproveitar o cache de camadas do Docker:
# a instalacao das dependencias so roda de novo quando package.json muda.
COPY package*.json ./

# "npm ci" faz uma instalacao limpa e reproduzivel a partir do lock file.
RUN npm ci --omit=dev && npm cache clean --force

COPY app.js ./

# Executa como usuario nao privilegiado (a imagem node ja fornece o usuario "node").
USER node

EXPOSE 8080

CMD ["node", "app.js"]
