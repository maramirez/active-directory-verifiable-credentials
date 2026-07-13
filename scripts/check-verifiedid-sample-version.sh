#!/usr/bin/env bash
set -euo pipefail

DOTNET_SAMPLE_DIR="${DOTNET_SAMPLE_DIR:-/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet}"
NODE_SAMPLE_DIR="${NODE_SAMPLE_DIR:-/Users/maramirez/repos/active-directory-verifiable-credentials-node}"
DOTNET_UPSTREAM_URL="${DOTNET_UPSTREAM_URL:-https://github.com/Azure-Samples/active-directory-verifiable-credentials-dotnet.git}"
NODE_UPSTREAM_URL="${NODE_UPSTREAM_URL:-https://github.com/Azure-Samples/active-directory-verifiable-credentials-node.git}"

check_repo() {
  local label="$1"
  local repo_dir="$2"
  local upstream_url="$3"

  echo "== $label =="

  if [[ ! -d "$repo_dir/.git" ]]; then
    echo "missing local clone: $repo_dir"
    echo
    return
  fi

  local local_head upstream_head local_desc upstream_desc
  local_head="$(git -C "$repo_dir" rev-parse HEAD)"
  local_desc="$(git -C "$repo_dir" show -s --format='%h %cs %s' HEAD)"
  upstream_head="$(git ls-remote "$upstream_url" HEAD | awk '{print $1}')"
  upstream_desc="$(git ls-remote "$upstream_url" HEAD >/dev/null 2>&1 && git -C "$repo_dir" show -s --format='%h %cs %s' "$upstream_head" 2>/dev/null || true)"

  echo "local:    $local_desc"
  echo "upstream: ${upstream_desc:-$upstream_head}"

  if [[ "$local_head" == "$upstream_head" ]]; then
    echo "status:   up to date"
  else
    echo "status:   behind upstream"
    echo "commits missing locally:"
    git -C "$repo_dir" fetch origin >/dev/null 2>&1 || true
    git -C "$repo_dir" log --oneline HEAD..origin/main 2>/dev/null || echo "  unable to read origin/main locally"
  fi

  echo
}

echo "Verified ID sample version check"
echo "date: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

check_repo ".NET sample" "$DOTNET_SAMPLE_DIR" "$DOTNET_UPSTREAM_URL"
check_repo "Node sample" "$NODE_SAMPLE_DIR" "$NODE_UPSTREAM_URL"
