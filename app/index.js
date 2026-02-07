const http = require('http');
const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('HOLA HOLITA\n');
});
server.listen(3000, '0.0.0.0', () => {
  console.log('Servidor corriendo en el puerto 3000');
});
