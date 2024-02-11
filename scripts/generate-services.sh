#!/bin/bash

for i in {1..3}; do
SCOPE=services
WORKSPACE=foo-$i

mkdir -p $SCOPE/$WORKSPACE;
pushd $SCOPE/$WORKSPACE;

npm init -y;

cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "es2021",
    "module": "commonjs",
    "moduleResolution": "node",
    "sourceMap": true,
    "pretty": true,
    "outDir": "dist",
    "strict": false,
    "esModuleInterop": true
  },
  "include": [
    "src"
  ]
}
EOF

mkdir -p src;
cat > src/index.ts <<EOF
import * as http from 'http';
const port = process.env.APP_PORT ?? 3000;
const server = http.createServer(function(req, res) {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ name: '$WORKSPACE' }));
});
server.listen(port, () => {
  console.log('server is listening on ' + port);
});
EOF

node <<EOF
  const pkg = require('./package.json');
  pkg.scripts = { start: 'tsc && node dist/index.js', build: 'tsc' };
  require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
EOF

cat > Dockerfile <<EOF
FROM node:20-alpine as base

FROM base as builder
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
RUN apk update
WORKDIR /app
COPY . .
RUN npx -y turbo prune $WORKSPACE --docker

FROM base AS installer
RUN apk add --no-cache libc6-compat
RUN apk update
WORKDIR /app

COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/package-lock.json ./package-lock.json
RUN npm ci

COPY --from=builder /app/out/full/ .
RUN npm run build --if-present

FROM base AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 app
RUN adduser --system --uid 1001 app
USER app
COPY --from=installer /app .
CMD node $SCOPE/$WORKSPACE/dist/index.js
EOF

popd;

npm install --save-dev typescript @types/node -w $WORKSPACE;

done
