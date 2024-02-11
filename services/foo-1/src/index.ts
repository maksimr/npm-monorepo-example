import * as http from 'http';
import '@packages/foo-1/src/index';
const port = process.env.APP_PORT ?? 3000;
const server = http.createServer(function(req, res) {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ name: 'foo-1', date: new Date()}));
});
server.listen(port, () => {
  console.log('server is listening on ' + port);
});
