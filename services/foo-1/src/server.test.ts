import { afterEach, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert';
import { server } from './server';

describe('server', () => {
  beforeEach((_, done) => {
    server.listen(3000, done);
  });

  afterEach((_, done) => {
    server.close(done);
  });

  it('should respond with a json object', async () => {
    const json = await fetch('http://localhost:3000').then((res) => {
      return res.json();
    });

    assert.equal(json.name, 'foo-1');
    assert.equal(json.url, '/');
  });
});
