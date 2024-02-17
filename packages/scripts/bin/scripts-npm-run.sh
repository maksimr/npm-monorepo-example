#!/bin/bash

# Usage: $0 -w <workspace> <npm-command> [args]
#    -w <workspace>   Workspace to run the npm command in
#    <npm-command>    NPM command to run in each package
#    [args]           Arguments to pass to the npm command
#
# The script has the same api as the npm run command, 
# but it runs the specified npm command in each associated workspace.

# This script is used to run npm commands in a monorepo workspace.
# It accepts a workspace name and an npm command as arguments.
# The script first checks if the workspace name and npm command are provided.
# If not, it displays the usage information and exits with an error code.
# The script then creates an output directory for storing the results of the 'turbo prune' command.
# It removes any existing output directory before running the 'turbo prune' command.
# After that, it finds all the associated workspaces by searching for package.json files in the output directory.
# For each associated workspace, it extracts the package name from the package.json file.
# Finally, it runs the specified npm command in each associated workspace using the 'npm run' command.
# The script runs the npm commands in parallel using the '&' operator and waits for all commands to finish using the 'wait' command.

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

ASSOCIATED_WORKSPACES=$(find "$OUTPUT_DIR" -name package.json -mindepth 2);
for package_json in $ASSOCIATED_WORKSPACES
do
  PACKAGE_NAME=$(node -p "require('$package_json').name")
  npm run -w "$PACKAGE_NAME" --if-present "${NPM_COMMAND_ARGS[@]}" &
done

wait
