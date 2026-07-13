#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/1-asp-net-core-api-idtokenhint"

if [[ -x "$HOME/.dotnet/dotnet" ]]; then
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$HOME/.dotnet:$PATH"
fi

cd "$PROJECT_DIR"
DOTNET_ENVIRONMENT=Development dotnet run
