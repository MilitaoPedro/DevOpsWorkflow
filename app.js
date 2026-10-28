const express = require('express');

const app = express();
const PORT = process.env.PORT || 8080;

// Mensagem retornada pelo endpoint. Alterada de "Hello World" para
// "Hello World 2" na versao 2.0 da aplicacao.
const MESSAGE = 'Hello World';

app.get('/hello', (req, res) => {
  res.type('text/plain').send(MESSAGE);
});

app.get('/', (req, res) => {
  res.type('text/plain').send(MESSAGE);
});

app.listen(PORT, () => {
  console.log(`Aplicacao ouvindo na porta ${PORT}`);
});
