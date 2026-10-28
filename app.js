const express = require('express');

const app = express();
const PORT = process.env.PORT || 8080;

// Mensagem retornada pelo endpoint. Era "Hello World" na versao 1.0.
const MESSAGE = 'Hello World 2';

app.get('/hello', (req, res) => {
  res.type('text/plain').send(MESSAGE);
});

app.get('/', (req, res) => {
  res.type('text/plain').send(MESSAGE);
});

app.listen(PORT, () => {
  console.log(`Aplicacao ouvindo na porta ${PORT}`);
});
