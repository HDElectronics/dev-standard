---
id: MOB
title: Mobile apps
version: 0.1.0
applies_to: pack
based_on:
  - name: OWASP MASVS
    url: https://mas.owasp.org/MASVS/
  - name: OWASP MASTG
    url: https://mas.owasp.org/MASTG/
---

# Mobile apps (MOB)

An opt-in pack for iOS and Android apps. Rules follow the OWASP Mobile Application Security Verification Standard (MASVS) control groups; the Mobile Application Security Testing Guide (MASTG) describes how to test each one. The app talks to the same FastAPI backend, so the production pack still applies to the server side.

## Rules

### MOB-001 · MUST · Store secrets only in the platform keystore (MASVS-STORAGE, MASVS-CRYPTO)

Tokens, keys and credentials live in the iOS Keychain or Android Keystore. Never in shared preferences, plain files, SQLite, logs or the clipboard. No API secrets are compiled into the app.

- **Why:** Anything in app storage or the binary can be read on a rooted or jailbroken device or from a backup.
- **Check:** MobSF static scan in CI; a test or review checklist confirms the storage API used for tokens.

### MOB-002 · MUST · Use TLS only and validate certificates (MASVS-NETWORK)

All traffic uses HTTPS. Cleartext traffic is disabled (Android `usesCleartextTraffic="false"` or a network security config, iOS App Transport Security without exceptions). Certificate validation is never disabled, including in debug builds that may ship.

- **Why:** Mobile devices often join untrusted Wi-Fi, where interception is easy.
- **Check:** MobSF scan flags cleartext and trust-all configurations; build fails on findings.

### MOB-003 · MUST · Authenticate with the system browser and PKCE (MASVS-AUTH)

Log in through the identity provider (Keycloak) using the authorization code flow with PKCE in the system browser or an auth session (AppAuth), per RFC 8252. Never collect the user's password in an embedded web view.

- **Why:** Embedded web views let the app read credentials and prevent the user from verifying the login page (RFC 8252).
- **Check:** Dependency check for AppAuth or the platform auth session API; review checklist.

### MOB-004 · MUST · Validate deep links and IPC input (MASVS-PLATFORM)

Treat deep links, intents, URL schemes and data from other apps as untrusted input: validate parameters, and never trigger sensitive actions from a link without user confirmation. Prefer verified App Links and Universal Links over custom schemes.

- **Why:** Custom URL schemes can be claimed by any app and used to inject parameters.
- **Check:** Unit tests for each deep-link handler with malformed and malicious input.

### MOB-005 · SHOULD · Keep the app updated and its dependencies scanned (MASVS-CODE)

Enforce a minimum supported app version from the server, keep the minimum OS version current, and scan dependencies as in SEC-002.

- **Why:** Old app versions keep known vulnerabilities alive in users' hands.
- **Check:** Backend returns a "please update" response below the minimum version; dependency scanning in CI.

### MOB-006 · SHOULD · Minimize data collection and declare it (MASVS-PRIVACY)

Collect only the data the feature needs, request permissions at the moment they are used, and keep the App Store privacy label and Google Play data safety form accurate and in the repo.

- **Why:** Over-collection is a privacy risk and a common reason for store rejection.
- **Check:** advisory; the declarations are reviewed whenever DAT-001 classifications change.

## Reference

| Rule | MASVS group |
|------|-------------|
| MOB-001 | MASVS-STORAGE, MASVS-CRYPTO |
| MOB-002 | MASVS-NETWORK |
| MOB-003 | MASVS-AUTH |
| MOB-004 | MASVS-PLATFORM |
| MOB-005 | MASVS-CODE |
| MOB-006 | MASVS-PRIVACY |

MASVS-RESILIENCE (anti-tampering, anti-reverse-engineering) is not required by default; add it by ADR for apps that handle payments or high-value content.

## Sources

- [OWASP MASVS](https://mas.owasp.org/MASVS/)
- [OWASP MASTG](https://mas.owasp.org/MASTG/)
- [RFC 8252 OAuth 2.0 for Native Apps](https://www.rfc-editor.org/rfc/rfc8252)
- [MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF)
