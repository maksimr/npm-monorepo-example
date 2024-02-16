import { foo2 } from '@packages/foo-2/src/index';

foo2();

export function foo1() {
  console.log('foo-1:', 'Hello, world!', new Date());
}