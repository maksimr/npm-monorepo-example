import * as http from 'http';
import { foo1 } from '@packages/foo-1/src/index';

foo1();

export const server = http.createServer(function (req, res) {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    name: 'foo-1',
    url: req.url,
    date: new Date()
  }));
});
