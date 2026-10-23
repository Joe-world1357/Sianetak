# Working on Sianetak

## Before you change anything
Read `CLAUDE.md` (working rules), the SRS section relevant to your task, and the existing code in
the area you are touching. Reuse what is there rather than adding a parallel way to do the same
thing.

## Conventions
- **Backend:** controllers validate and present; services hold business rules; entities and
  migrations define the schema. Never enable `synchronize` — add a migration. Money is stored as
  integer minor units with an explicit currency.
- **Mobile:** presentation, domain and data stay separate. All user-facing text goes in both ARB
  files. Use directional spacing so RTL mirrors correctly.
- **Security:** validate on the server, enforce authorization on the server, and never log phone
  numbers, OTP codes, tokens or SQL parameters.
- **Policy:** do not hard-code commission rates, fees, cancellation rules or prices. Unresolved
  decisions (SRS section 20) stay configurable and clearly marked.

## Definition of done
Acceptance criteria pass, tests are added or updated, `lint`/`analyze`/`typecheck` are clean, both
languages and RTL are checked for any UI change, and the README is updated if setup changed.

```bash
cd backend && npm run lint && npm run typecheck && npm test && npm run test:e2e
cd mobile  && flutter analyze && flutter test
```
