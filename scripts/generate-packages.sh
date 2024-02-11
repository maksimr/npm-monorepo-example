#!/bin/bash

for i in {1..2}; do
SCOPE=packages
WORKSPACE=foo-$i

mkdir -p $SCOPE/$WORKSPACE;
pushd $SCOPE/$WORKSPACE;

npm init -y --scope=$SCOPE;

cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "es2021",
    "module": "commonjs",
    "moduleResolution": "node",
    "sourceMap": true,
    "pretty": true,
    "outDir": "dist/src",
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
console.log('$WORKSPACE:', 'Hello, world!');
EOF

node <<EOF
  const pkg = require('./package.json');
  pkg.scripts = { build: 'tsc' };
  require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
EOF

node <<EOF
  const pkg = require('./package.json');
  pkg.exports = { './*': './dist/*.js' };
  require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
EOF

popd;

npm install --save-dev typescript @types/node -w @$SCOPE/$WORKSPACE;

done
