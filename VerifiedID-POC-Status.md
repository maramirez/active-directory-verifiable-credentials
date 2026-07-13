# Verified ID POC Status

This repository is not the runnable Microsoft sample itself. It is acting as the workspace for:

- local helper scripts
- credential contract files
- implementation notes
- deployment planning

The current official Microsoft Learn issuer tutorial points to the dedicated `.NET` sample repository:

- Tutorial: https://learn.microsoft.com/en-us/entra/verified-id/verifiable-credentials-configure-issuer
- Sample repo: https://github.com/Azure-Samples/active-directory-verifiable-credentials-dotnet

## Current official sample status

As checked on 2026-06-18:

- Latest upstream `.NET` sample commit: `e61bef293abb195db7fdd881c67196bb50a6e583`
- Commit date: `2026-06-03`
- Local clone path: `/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet`
- Local clone current commit: `262ab95`

The upstream changes after `262ab95` add a new sample:

- `7-AccountRecovery-ClaimsMatching`

Those changes do not replace or rewrite the existing issuer sample:

- `1-asp-net-core-api-idtokenhint`

They also do not replace or rewrite the current helpdesk sample:

- `6-woodgrove-helpdesk`

## What is already working on this Mac

Validated on 2026-06-18:

- `.NET 8` is installed at `$HOME/.dotnet`
- The local launcher script uses that runtime
- The issuer/verifier sample starts successfully on `http://localhost:5000`
- The local sample has an `appsettings.Development.json` configured for the Barry tenant

Relevant files:

- Issuer sample launcher: [scripts/run-idtokenhint-local.sh](/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/run-idtokenhint-local.sh)
- Two-track test guide: [VerifiedID-Two-Track-Local-Testing.md](/Users/maramirez/repos/active-directory-verifiable-credentials/VerifiedID-Two-Track-Local-Testing.md)
- Student password reset guide: [VerifiedID-PasswordReset-Implementation-Guide.md](/Users/maramirez/repos/active-directory-verifiable-credentials/VerifiedID-PasswordReset-Implementation-Guide.md)

## Recommended POC path

Use two tracks:

1. Start with `1-asp-net-core-api-idtokenhint` to prove issuance and verification end to end on this Mac.
2. Move to `6-woodgrove-helpdesk` when we want a user-facing verification experience closer to a support or password-reset flow.
3. Review `7-AccountRecovery-ClaimsMatching` before deployment planning, because it is the newest upstream sample and may be useful for production-style identity matching.

## Working next step

Run the issuer sample locally:

```bash
/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/run-idtokenhint-local.sh
```

Expose it publicly in another terminal:

```bash
npx -y localtunnel --port 5000
```

Then:

1. Open the returned `https://*.loca.lt` URL.
2. Click `Get Credential`.
3. Scan with Microsoft Authenticator.
4. Complete issuance.
5. Click `Verify Credential` and present the same card.

## Security note

The local sample currently uses a plaintext client secret in:

- `/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/1-asp-net-core-api-idtokenhint/appsettings.Development.json`

Before broader testing or deployment:

1. Rotate that secret.
2. Move local secrets to user-secrets or environment variables.
3. Use Key Vault or managed identity for deployed environments.
