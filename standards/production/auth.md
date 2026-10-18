---
id: AUTH
title: Authentication and authorization
version: 0.1.0
applies_to: deployed
based_on:
  - name: RFC 9700 (Best Current Practice for OAuth 2.0 Security)
    url: https://www.rfc-editor.org/rfc/rfc9700
  - name: OpenID Connect Core 1.0
    url: https://openid.net/specs/openid-connect-core-1_0.html
  - name: NIST SP 800-63B
    url: https://pages.nist.gov/800-63-4/sp800-63b.html
  - name: RFC 8725 (JWT Best Current Practices)
    url: https://www.rfc-editor.org/rfc/rfc8725
  - name: OWASP ASVS 5.0
    url: https://owasp.org/www-project-application-security-verification-standard/
---

# Authentication and authorization (AUTH)

Who the user is, how that is proven, and what they may do. The default identity provider is Keycloak. For a React SPA with a FastAPI backend, FastAPI acts as a backend-for-frontend (BFF), as recommended by the IETF draft "OAuth 2.0 for Browser-Based Applications": it runs the OIDC flow and gives the browser only an HttpOnly session cookie. Tokens never reach JavaScript.

## Rules

### AUTH-001 · MUST NOT · Write your own auth or crypto

Use an OIDC provider (Keycloak by default) or a maintained library. Do not implement password storage, token signing, session management or cryptographic primitives yourself. Choosing a provider other than Keycloak needs an ADR.

- **Why:** Hand-made auth is where the most damaging vulnerabilities come from. Providers ship MFA, passkeys, lockout and audit logs already tested.
- **Check:** advisory, enforced by review. `dev-standard check deps` flags added imports of low-level crypto (`cryptography.hazmat`); a module that legitimately needs them gets an `AUTH-001` waiver scoped to its path.

### AUTH-002 · MUST · Use authorization code with PKCE, per RFC 9700

OAuth and OIDC flows use the authorization code grant with PKCE (`S256`). Redirect URIs match exactly, with no wildcards. The implicit grant and the resource owner password grant are not used.

- **Why:** RFC 9700 deprecates implicit and password grants because they leak tokens or credentials. Exact matching prevents open-redirect token theft.
- **Check:** Keycloak realm export in the repo (`infra/keycloak/realm.json`) is linted in CI: `implicitFlowEnabled: false`, `directAccessGrantsEnabled: false`, `pkce.code.challenge.method: S256`, no `*` in `redirectUris`.

### AUTH-003 · MUST · Hash passwords with Argon2id and follow NIST 800-63B

If the system stores passwords at all (prefer letting Keycloak do it), hash them with Argon2id using the OWASP Password Storage Cheat Sheet parameters. Enforce minimum length and check new passwords against a breached-password list, per NIST SP 800-63B. Do not impose composition rules or periodic forced rotation.

- **Why:** Argon2id resists GPU cracking. NIST found composition rules and forced rotation lead to weaker, reused passwords.
- **Check:** Keycloak password policy in the realm export (`length`, `passwordBlacklist` or equivalent). For app-stored passwords, a unit test asserts the hash prefix `$argon2id$`.

### AUTH-004 · MUST · Keep browser sessions in hardened cookies

The BFF sets the session cookie with `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict`), and the `__Host-` prefix. Rotate the session ID at login and on privilege change. Apply an idle timeout and an absolute timeout.

- **Why:** These flags block script access, plaintext transport and most cross-site sending. Rotation prevents session fixation.
- **Check:** Integration test logs in and asserts the `Set-Cookie` attributes and that the session ID differs before and after login. ZAP baseline scan (WEB-002) flags missing flags.

### AUTH-005 · MUST · Keep tokens short-lived and validate JWTs per RFC 8725

Access tokens live 15 minutes or less. Refresh tokens rotate on every use, and reuse of an old refresh token revokes the whole family. Services validate JWTs per RFC 8725: pin the expected algorithm (for example `RS256`), and check `iss`, `aud`, `exp` and `nbf`. Fetch keys from the provider's JWKS endpoint and cache them.

- **Why:** Short lifetimes limit the damage of a leaked token. Not pinning the algorithm allows `alg: none` and key-confusion attacks.
- **Check:** Unit tests feed the validator tokens with a wrong `aud`, expired `exp`, `alg: none` and an HS256 token signed with the public key; all must be rejected. Keycloak realm export: `accessTokenLifespan <= 900`, `revokeRefreshToken: true`.

### AUTH-006 · MUST · Authorize every request on the server, deny by default

Every endpoint declares its required permission. Check it on the server for every request, including object-level ownership: a user can read order 42 only if order 42 is theirs or they hold a role that allows it. Missing permission means deny.

- **Why:** Broken object-level authorization (BOLA) is risk #1 in the OWASP API Security Top 10.
- **Check:** A test enumerates all FastAPI routes and fails if any route lacks an auth dependency or an explicit `public` marker. Per-resource tests call with another user's ID and expect `403` or `404`.

### AUTH-007 · MUST · Require MFA for privileged accounts

Admin and staff accounts require MFA, preferably passkeys (WebAuthn) or TOTP. Offer passkeys to all users.

- **Why:** Most account takeovers use stolen or guessed passwords. A second factor stops them.
- **Check:** Keycloak realm export: the admin group has the `CONFIGURE_TOTP` or WebAuthn required action, or a conditional OTP flow on the `admin` role. Checked in the PRR.

### AUTH-008 · MUST · Audit-log security events

Write logins, failed logins, logouts, password resets, MFA changes and role or permission changes to an audit log with timestamp, actor, subject, source IP and outcome. The audit log is append-only and kept separate from debug logs.

- **Why:** You cannot investigate an incident you didn't record.
- **Check:** Keycloak event logging enabled (`eventsEnabled: true`, `adminEventsEnabled: true`) in the realm export. App-side events tested with a log capture fixture.

## Reference

### Architecture

```text
Browser (React SPA)
   │  HttpOnly session cookie only
   ▼
FastAPI BFF  ──── OIDC code + PKCE ────►  Keycloak
   │  server-side session (Redis): access + refresh tokens
   ▼
FastAPI APIs / other services   ◄── validate JWT via Keycloak JWKS
```

### Keycloak for local development (example)

```yaml
# compose.yaml (excerpt)
services:
  keycloak:
    image: quay.io/keycloak/keycloak:<pinned-version>
    command: start-dev --import-realm
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
    volumes:
      - ./infra/keycloak:/opt/keycloak/data/import:ro
    ports: ["8080:8080"]
```

`start-dev` is for local use only. Production runs `start` with a real database, TLS and a hostname configured.

### BFF login flow in FastAPI (example)

Authlib's Starlette integration handles discovery, PKCE and the token exchange.

```python
# app/auth/bff.py (example)
from authlib.integrations.starlette_client import OAuth
from fastapi import APIRouter, Request
from fastapi.responses import RedirectResponse

from app.config import settings

oauth = OAuth()
oauth.register(
    name="keycloak",
    server_metadata_url=f"{settings.oidc_issuer}/.well-known/openid-configuration",
    client_id=settings.oidc_client_id,
    client_secret=settings.oidc_client_secret,
    client_kwargs={"scope": "openid profile email", "code_challenge_method": "S256"},
)

router = APIRouter(prefix="/auth")


@router.get("/login")
async def login(request: Request):
    return await oauth.keycloak.authorize_redirect(request, settings.oidc_redirect_uri)


@router.get("/callback")
async def callback(request: Request):
    token = await oauth.keycloak.authorize_access_token(request)
    request.session.clear()  # rotate: drop any pre-login session data (AUTH-004)
    request.session["user"] = token["userinfo"]
    # Store tokens server side (Redis), keyed by session ID; never send them to the browser.
    return RedirectResponse(settings.frontend_url)
```

The session middleware must be server-side (session ID in the cookie, data in Redis). Starlette's default `SessionMiddleware` stores data in a signed cookie, so do not put tokens in it.

### Validating JWTs in an API (example)

```python
# app/auth/jwt.py (example, PyJWT)
import jwt
from jwt import PyJWKClient

from app.config import settings

_jwks = PyJWKClient(f"{settings.oidc_issuer}/protocol/openid-connect/certs")


def verify_access_token(token: str) -> dict:
    key = _jwks.get_signing_key_from_jwt(token)
    return jwt.decode(
        token,
        key.key,
        algorithms=["RS256"],          # pinned (RFC 8725)
        audience=settings.oidc_audience,
        issuer=settings.oidc_issuer,
        options={"require": ["exp", "iss", "aud"]},
    )
```

## Sources

- [RFC 9700: Best Current Practice for OAuth 2.0 Security](https://www.rfc-editor.org/rfc/rfc9700)
- [IETF draft: OAuth 2.0 for Browser-Based Applications](https://datatracker.ietf.org/doc/draft-ietf-oauth-browser-based-apps/)
- [RFC 8725: JWT Best Current Practices](https://www.rfc-editor.org/rfc/rfc8725)
- [NIST SP 800-63B](https://pages.nist.gov/800-63-4/sp800-63b.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OWASP API Security Top 10: API1 BOLA](https://owasp.org/API-Security/)
- [Keycloak documentation](https://www.keycloak.org/documentation)
