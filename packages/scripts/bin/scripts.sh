#!/bin/bash

# Usage: scripts.sh -w <workspace> <npm-command> [args]
#    -w <workspace>   Workspace to run the npm command in
#    <npm-command>    NPM command to run in each package
#    [args]           Arguments to pass to the npm command

WORKSPACE=""
NPM_COMMAND_ARGS=("$@")
for ((i=0; i<"${#NPM_COMMAND_ARGS[@]}"; ++i)); do
    case ${NPM_COMMAND_ARGS[i]} in
        -w) 
          WORKSPACE="${NPM_COMMAND_ARGS[i+1]}";
          unset "NPM_COMMAND_ARGS[i]"; 
          unset "NPM_COMMAND_ARGS[i+1]"; 
          break;;
    esac
done

if [ -z "${NPM_COMMAND_ARGS[*]}" ] || [ -z "$WORKSPACE" ]; then
  echo "Usage: $0 -w <workspace> <npm-command> [args]"
  exit 1
fi

OUTPUT_DIR="/tmp/turbo-prune/$WORKSPACE"

rm -rf "$OUTPUT_DIR"
npx -y turbo prune "$WORKSPACE" --out-dir="$OUTPUT_DIR" &> /dev/null

for package_json in $(find "$OUTPUT_DIR" -name package.json -mindepth 2)
do
  PACKAGE_NAME=$(node -p "require('$package_json').name")
  npm run -w "$PACKAGE_NAME" --if-present "${NPM_COMMAND_ARGS[@]}" &
done

wait
