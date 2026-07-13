# Verified ID Local Testing: Two-Track Setup

This setup splits local testing into two separate project tracks:

1. **Track A - Issue + Verify in one app**
   - Project: `/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/1-asp-net-core-api-idtokenhint`
   - Purpose: issue a credential to Authenticator (`Get Credential`) and verify it (`Verify Credential`) in the same sample.

2. **Track B - Helpdesk verification flow**
   - Project: `/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/6-woodgrove-helpdesk`
   - Purpose: verify previously issued credentials in a support/helpdesk UX.

## Current local files prepared

- Track A config: `/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/1-asp-net-core-api-idtokenhint/appsettings.Development.json`
- Track B config: `/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/6-woodgrove-helpdesk/appsettings.Development.json`
- Track A launcher: `/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/run-idtokenhint-local.sh`
- Track B launcher: `/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/run-woodgrove-local.sh`

Both development config files are excluded from git in local `.git/info/exclude`.

## Test order (recommended)

1. Run **Track A** first and issue a credential to your Authenticator wallet.
2. Verify in **Track A** to confirm wallet + tenant + config are good.
3. Then run **Track B** and verify with the same wallet card.

## Running Track A (issue + verify)

Terminal A:

```bash
/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/run-idtokenhint-local.sh
```

Terminal B (public callback URL):

```bash
npx -y localtunnel --port 5000
```

Then:

1. Open the `https://*.loca.lt` URL.
2. Click `Get Credential` and add the card in Authenticator.
3. Click `Verify Credential` and present the same card.

## Running Track B (helpdesk)

Terminal A:

```bash
/Users/maramirez/repos/active-directory-verifiable-credentials/scripts/run-woodgrove-local.sh
```

Terminal B:

```bash
npx -y localtunnel --port 5000
```

Then:

1. Open the `https://*.loca.lt` URL.
2. Click `I already have my card`.
3. Present the wallet card issued in Track A.

## Notes

- For now, `woodgrove` is configured with `useFaceCheck=false` for local testing without premium billing.
- If Authenticator shows a generic scan error, verify that the requested `CredentialType` matches the card currently in wallet.
