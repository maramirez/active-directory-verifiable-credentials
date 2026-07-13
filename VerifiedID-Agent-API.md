# Barry University Verified ID — Agent API Reference

**Base URL:** `https://id.labs.barry.edu`  
**Auth header:** `X-Agent-Key: <your-key>` (required on all endpoints)

---

## Recommended flow

```
1. Check status      → has user set up their Digital ID?
        ↓ no         → tell user to visit id.labs.barry.edu (Step 1)
        ↓ yes
2. Start verification → get verifyUrl + sessionId
        ↓
   Send verifyUrl to user → "tap this link, then come back and say done"
        ↓
   Wait for user to reply (do NOT poll continuously)
        ↓
3. Poll result (once, on user reply) → handle status
```

> **Timeout:** Microsoft Verified ID sessions expire after ~5 minutes. If the result
> comes back `expired`, automatically call endpoint 2 again and send the user a fresh link.

---

## Endpoint 1 — Check if user has configured Verified ID

```
GET /api/agent/user/status?email={upn}
```

Call this before starting a verification. Only users who have completed setup
(gone through Step 1 at id.labs.barry.edu) can fulfill a verification request.

### Query parameters

| Parameter | Type   | Required | Description                              |
|-----------|--------|----------|------------------------------------------|
| `email`   | string | yes      | User's Barry University UPN (e.g. `jdoe@barry.edu`) |

### Request

```http
GET https://id.labs.barry.edu/api/agent/user/status?email=jdoe@barry.edu
X-Agent-Key: <your-key>
```

### Response — configured

```json
{
  "configured": true,
  "configuredAt": "2026-07-13T17:58:18Z"
}
```

### Response — not configured

```json
{
  "configured": false
}
```

Prompt the user to visit `https://id.labs.barry.edu` and complete Step 1 before proceeding.

---

## Endpoint 2 — Start a verification session

```
POST /api/agent/verify/start
```

Creates a verification session. Returns a `verifyUrl` to send to the user and a
`sessionId` to poll for the result.

The optional `require` block adds a cryptographic constraint — Microsoft Verified ID
will reject any credential whose claims don't match. **Always include it when you know
who you're talking to.** This prevents a different person from scanning the link and
spoofing the verification.

### Request body

| Field           | Type   | Required | Description                                                  |
|-----------------|--------|----------|--------------------------------------------------------------|
| `require`       | object | no       | Claim constraints. Omit to allow any valid Barry credential. |
| `require.email` | string | no       | Enforce that the credential's email matches this UPN. Recommended — UPN is unique per person. |

### Request — with identity constraint (recommended)

```http
POST https://id.labs.barry.edu/api/agent/verify/start
X-Agent-Key: <your-key>
Content-Type: application/json

{
  "require": {
    "email": "jdoe@barry.edu"
  }
}
```

### Request — no constraint (any valid Barry credential)

```http
POST https://id.labs.barry.edu/api/agent/verify/start
X-Agent-Key: <your-key>
Content-Type: application/json

{}
```

### Response

```json
{
  "sessionId": "a3f1b2c4-...",
  "verifyUrl": "https://id.labs.barry.edu/verify?id=a3f1b2c4-...",
  "expiresAt": "2026-07-13T18:05:00Z"
}
```

| Field       | Description                                         |
|-------------|-----------------------------------------------------|
| `sessionId` | Store this — pass it to endpoint 3 to poll for the result |
| `verifyUrl` | An `https://` link — send this directly to the user in chat, email, or Teams. On mobile it opens Microsoft Authenticator automatically. On desktop it shows a QR code to scan. |
| `expiresAt` | Session is valid for ~5 minutes from creation       |

---

## Endpoint 3 — Poll verification result

```
GET /api/agent/verify/result?sessionId={id}
```

Returns the current status of a verification session. **Do not poll continuously.**
Poll once when the user signals they have completed the step (e.g. they reply "done").

### Query parameters

| Parameter   | Type   | Required | Description                                  |
|-------------|--------|----------|----------------------------------------------|
| `sessionId` | string | yes      | The `sessionId` returned by endpoint 2       |

### Request

```http
GET https://id.labs.barry.edu/api/agent/verify/result?sessionId=a3f1b2c4-...
X-Agent-Key: <your-key>
```

### Response

```json
{
  "status": "verified",
  "verified": true,
  "identity": {
    "given_name": "John",
    "family_name": "Doe",
    "email": "jdoe@barry.edu"
  }
}
```

### Status values

| Status     | `verified` | Meaning                                      | Action                                          |
|------------|------------|----------------------------------------------|-------------------------------------------------|
| `pending`  | false      | Link not yet opened                          | Wait for user to reply, then poll again         |
| `opened`   | false      | User opened Authenticator                    | Wait for user to reply, then poll again         |
| `verified` | true       | Identity confirmed                           | Read `identity` and proceed                     |
| `error`    | false      | User declined or credential did not match    | Inform user, offer to retry                     |
| `expired`  | false      | Session timed out (~5 min)                   | Call endpoint 2 again, send user a fresh link   |

---

## Conversational flow example

```
User:  I need to reset my password. My email is jdoe@barry.edu.

       [agent calls GET /api/agent/user/status?email=jdoe@barry.edu]
       → configured: true

       [agent calls POST /api/agent/verify/start with require.email]
       → gets sessionId + verifyUrl

Agent: To verify your identity, tap this link on your phone and follow
       the steps in Microsoft Authenticator — it takes about 30 seconds:

       https://...

       Come back here and say "done" when you've completed it.

User:  done

       [agent calls GET /api/agent/verify/result?sessionId=...]
       → status: verified

Agent: Identity confirmed. Proceeding to reset your password...
```

### Handling each status on the user's reply

| Status     | Agent response                                                                 |
|------------|--------------------------------------------------------------------------------|
| `verified` | Proceed — use `identity.email` to confirm who was verified                    |
| `pending`  | "I don't see the verification yet — make sure you tapped Share in Authenticator. Try again and let me know." |
| `expired`  | Auto-restart: call endpoint 2, send new link — "That link expired, here's a fresh one: [url]" |
| `error`    | "The verification didn't go through. Did you use the right account? Want to try again?" |

---

## Error responses

All endpoints return standard error shapes:

```json
{ "error": "Invalid or missing X-Agent-Key header" }   // 401
{ "error": "email query parameter is required" }        // 400
{ "error": "server_error", "error_description": "..." } // 500
```
