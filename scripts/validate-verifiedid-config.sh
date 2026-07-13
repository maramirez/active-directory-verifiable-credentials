#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/1-asp-net-core-api-idtokenhint/appsettings.Development.json}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

python3 - "$CONFIG_FILE" <<'PY'
import base64
import datetime as dt
import json
import sys
import urllib.parse
import urllib.request

config_path = sys.argv[1]
cfg = json.load(open(config_path, "r", encoding="utf-8"))
v = cfg["VerifiedID"]

tenant_id = v["TenantId"]
client_id = v["ClientId"]
client_secret = v["ClientSecret"]
scope = v.get("scope", "3db474b9-6a0c-4840-96ac-1fceb342124f/.default")
authority = v["DidAuthority"]
manifest_url = v["CredentialManifest"]
credential_type = v.get("CredentialType", "VerifiedCredentialExpert")
api_endpoint = v.get("ApiEndpoint", "https://verifiedid.did.msidentity.com/v1.0/verifiableCredentials/")

print(f"Config: {config_path}")
print(f"TenantId: {tenant_id}")
print(f"DidAuthority: {authority}")
print(f"CredentialType: {credential_type}")
print(f"Manifest URL: {manifest_url}")
print()

token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
token_body = urllib.parse.urlencode(
    {
        "client_id": client_id,
        "client_secret": client_secret,
        "scope": scope,
        "grant_type": "client_credentials",
    }
).encode()

req = urllib.request.Request(token_url, data=token_body, method="POST")
req.add_header("Content-Type", "application/x-www-form-urlencoded")
token_resp = json.load(urllib.request.urlopen(req, timeout=30))
access_token = token_resp["access_token"]
print("Access token: acquired")

manifest_resp = json.load(urllib.request.urlopen(manifest_url, timeout=30))
if "token" in manifest_resp:
    jwt = manifest_resp["token"]
    payload = jwt.split(".")[1] + "=" * (-len(jwt.split(".")[1]) % 4)
    manifest = json.loads(base64.urlsafe_b64decode(payload.encode()))
    iat = manifest.get("iat")
    manifest_id = manifest.get("id")
    manifest_issuer = manifest.get("iss")
    issue_time = dt.datetime.fromtimestamp(iat, dt.UTC).isoformat() if iat else "unknown"
    print(f"Manifest fetch: OK")
    print(f"Manifest id: {manifest_id}")
    print(f"Manifest issuer: {manifest_issuer}")
    print(f"Manifest iat: {issue_time}")
else:
    manifest = manifest_resp
    print("Manifest fetch: OK (JSON)")

print()

payload = {
    "authority": authority,
    "includeQRCode": False,
    "registration": {
        "clientName": "Verified ID config validator",
        "purpose": "Configuration validation",
    },
    "callback": {
        "url": "https://example.com/api/issuer/issuecallback",
        "state": "config-validator",
        "headers": {"api-key": "config-validator"},
    },
    "type": credential_type,
    "manifest": manifest_url,
    "claims": {
        "given_name": "Megan",
        "family_name": "Bowen",
    },
}

body = json.dumps(payload).encode()
req = urllib.request.Request(
    api_endpoint.rstrip("/") + "/createIssuanceRequest",
    data=body,
    method="POST",
)
req.add_header("Authorization", f"Bearer {access_token}")
req.add_header("Content-Type", "application/json")

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        response = json.load(resp)
        print("Issuance request validation: OK")
        print(json.dumps(response, indent=2))
except urllib.error.HTTPError as e:
    err_text = e.read().decode("utf-8", errors="replace")
    print(f"Issuance request validation: FAILED ({e.code})")
    print(err_text)
    sys.exit(2)
PY
