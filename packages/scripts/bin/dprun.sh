#!/bin/bash

# This script is used to run a npm command
# in all workspaces that are dependencies 
# of the given workspace

NPM_COMMAND=$1
WORKSPACE=$2
OUTPUT_DIR="/tmp/turbo-prune/$WORKSPACE"

if [ -z "$NPM_COMMAND" ] || [ -z "$WORKSPACE" ]; then
  echo "Usage: $0 <npm-command> <workspace>"
  exit 1
fi

rm -rf "$OUTPUT_DIR"
npx -y turbo prune "$WORKSPACE" --out-dir="$OUTPUT_DIR" &> /dev/null

find "$OUTPUT_DIR" -name package.json -mindepth 2 | while read -r package_json; do
  PACKAGE_NAME=$(node -p "require('$package_json').name")
  if [ "$PACKAGE_NAME" = "$WORKSPACE" ]; then
    continue
  fi

  npm run "$NPM_COMMAND" -w "$PACKAGE_NAME" --if-present
done
