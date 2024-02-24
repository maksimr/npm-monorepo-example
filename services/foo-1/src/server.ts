import * as http from 'http';
import { foo1 } from '@packages/foo-1/src/index';

foo1();

const config = {
  foo2: { url: process.env.FOO_2_URL || 'http://localhost:3002' },
  foo3: { url: process.env.FOO_3_URL || 'http://localhost:3003' }
}

console.log('config', config);

export const server = http.createServer(async function (req, res) {
  res.writeHead(200, { 'Content-Type': 'application/json' });

  if (req.url === '/proxy/foo-2') {
    const response = await fetch(config.foo2.url).then(response => response.json());
    console.log('response', response);
    res.end(JSON.stringify(response));
    return;
  }

  if (req.url === '/proxy/foo-3') {
    const response = await fetch(config.foo3.url).then(response => response.json());
    console.log('response', response);
    res.end(JSON.stringify(response));
    return;
  }

  res.end(JSON.stringify({
    name: 'foo-1',
    url: req.url,
    date: new Date()
  }));
});
