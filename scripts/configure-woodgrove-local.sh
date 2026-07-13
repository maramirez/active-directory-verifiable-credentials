#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/6-woodgrove-helpdesk"
DEV_SETTINGS_FILE="$PROJECT_DIR/appsettings.Development.json"
GIT_EXCLUDE_FILE="/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/.git/info/exclude"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

required_vars=(TENANT_ID CLIENT_ID CLIENT_SECRET DID_AUTHORITY)
missing=()
for v in "${required_vars[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    missing+=("$v")
  fi
done

if [[ -z "${CREDENTIAL_TYPE:-}" && -z "${CREDENTIAL_MANIFEST:-}" ]]; then
  missing+=("CREDENTIAL_TYPE or CREDENTIAL_MANIFEST")
fi

if (( ${#missing[@]} > 0 )); then
  echo "Missing required environment variables:" >&2
  printf ' - %s\n' "${missing[@]}" >&2
  echo >&2
  echo "Example:" >&2
  cat >&2 <<'USAGE'
TENANT_ID="<tenant-guid>" \
CLIENT_ID="<app-client-id>" \
CLIENT_SECRET="<app-client-secret>" \
DID_AUTHORITY="did:web:yourdomain" \
CREDENTIAL_TYPE="VerifiedEmployee" \
CREDENTIAL_MANIFEST="https://.../contracts/YourCredentialType" \
SOURCE_PHOTO_CLAIM="photo" \
EMAIL_CLAIM="mail" \
DISPLAYNAME_CLAIM="displayName" \
MATCH_CONFIDENCE="70" \
USE_FACE_CHECK="false" \
/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/configure-woodgrove-local.sh
USAGE
  exit 1
fi

# Optional overrides with safe defaults.
SOURCE_PHOTO_CLAIM="${SOURCE_PHOTO_CLAIM:-photo}"
EMAIL_CLAIM="${EMAIL_CLAIM:-mail}"
DISPLAYNAME_CLAIM="${DISPLAYNAME_CLAIM:-displayName}"
MATCH_CONFIDENCE="${MATCH_CONFIDENCE:-70}"
USE_FACE_CHECK="${USE_FACE_CHECK:-false}"

if [[ -z "${CREDENTIAL_TYPE:-}" && -n "${CREDENTIAL_MANIFEST:-}" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to derive credential type from CREDENTIAL_MANIFEST." >&2
    exit 1
  fi
  CREDENTIAL_TYPE="$(
    python3 - "$CREDENTIAL_MANIFEST" <<'PY'
import base64
import json
import sys
import urllib.request

url = sys.argv[1]
with urllib.request.urlopen(url, timeout=20) as r:
    data = json.load(r)
token = data.get("token")
if not token:
    raise SystemExit("Manifest response did not contain a token field")
parts = token.split(".")
if len(parts) < 2:
    raise SystemExit("Manifest token is not a valid JWT")
payload = parts[1] + "=" * (-len(parts[1]) % 4)
obj = json.loads(base64.urlsafe_b64decode(payload.encode()).decode())
types = obj.get("vc", {}).get("type", [])
if not isinstance(types, list) or len(types) < 2:
    raise SystemExit("Could not determine credential type from manifest")
print(types[-1])
PY
  )"
fi

cat > "$DEV_SETTINGS_FILE" <<EOF_SETTINGS
{
  "VerifiedID": {
    "TenantId": "$TENANT_ID",
    "Authority": "https://login.microsoftonline.com/",
    "scope": "3db474b9-6a0c-4840-96ac-1fceb342124f/.default",
    "ManagedIdentity": false,
    "ClientId": "$CLIENT_ID",
    "ClientSecret": "$CLIENT_SECRET",
    "DidAuthority": "$DID_AUTHORITY",
    "CredentialType": "$CREDENTIAL_TYPE",
    "EmailClaimName": "$EMAIL_CLAIM",
    "DisplayNameClaimName": "$DISPLAYNAME_CLAIM",
    "sourcePhotoClaimName": "$SOURCE_PHOTO_CLAIM",
    "matchConfidenceThreshold": $MATCH_CONFIDENCE
    ,"useFaceCheck": $USE_FACE_CHECK
  }
}
EOF_SETTINGS

if [[ -n "${CREDENTIAL_MANIFEST:-}" ]]; then
  if ! rg -q '"CredentialManifest"' "$DEV_SETTINGS_FILE"; then
    python3 - <<PY
import json
p = "$DEV_SETTINGS_FILE"
with open(p, "r", encoding="utf-8") as f:
    obj = json.load(f)
obj.setdefault("VerifiedID", {})["CredentialManifest"] = "${CREDENTIAL_MANIFEST}"
with open(p, "w", encoding="utf-8") as f:
    json.dump(obj, f, indent=2)
    f.write("\n")
PY
  fi
fi

if [[ -f "$GIT_EXCLUDE_FILE" ]] && ! rg -Fqx "6-woodgrove-helpdesk/appsettings.Development.json" "$GIT_EXCLUDE_FILE"; then
  echo "6-woodgrove-helpdesk/appsettings.Development.json" >> "$GIT_EXCLUDE_FILE"
fi

if [[ -x "$HOME/.dotnet/dotnet" ]]; then
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$HOME/.dotnet:$PATH"
fi

pushd "$PROJECT_DIR" >/dev/null
dotnet restore >/dev/null
dotnet build -c Debug >/dev/null
popd >/dev/null

cat <<DONE
Created: $DEV_SETTINGS_FILE
Credential type configured: $CREDENTIAL_TYPE

Next steps:
1) Terminal A:
   export DOTNET_ROOT="$HOME/.dotnet"
   export PATH="$HOME/.dotnet:$PATH"
   cd "$PROJECT_DIR"
   DOTNET_ENVIRONMENT=Development dotnet run

2) Terminal B (public URL for callback):
   npx -y localtunnel --port 5000

3) Open the returned https://*.loca.lt URL and click "I already have my card".
DONE
