---
status: proposed
date: 2026-10-18
decision-makers: Ibrahim Khadraoui
consulted: ""
informed: ""
---

# Default auth provider: Keycloak with FastAPI as backend-for-frontend

## Context and Problem Statement

Deployed apps need authentication that is free, easy to set up and follows OAuth security guidance (RFC 9700). Which provider and pattern?

## Decision Drivers

* Free and open source
* Easy to run: one container
* No tokens in the browser (UI-010)

## Considered Options

* Keycloak, FastAPI as backend-for-frontend
* Zitadel or Authentik
* A managed free tier (Auth0, Clerk)
* A library inside the app (Better Auth, Authlib only)

## Decision Outcome

Chosen option: "Keycloak, FastAPI as backend-for-frontend", because it is free, CNCF-hosted, runs as one container, supports MFA and passkeys, and the BFF pattern keeps tokens server side.

### Consequences

* Good, because no vendor lock-in or per-user cost
* Bad, because you operate Keycloak yourself (upgrades, backups)
