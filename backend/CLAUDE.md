# backend/: account and persistence API

Node.js + TypeScript (type stripping, erasable syntax only, `.ts` imports) with Fastify and
pg. It is the only writer of durable player state (CLAUDE.md "Boundaries").

- **SQL** is parameterised, always. Schema changes only through a new file in
  `migrations/`; an applied migration is never edited (checksums enforce it). New
  migrations get a fresh-database test and an existing-database test.
- **Never trust the client** for damage, currency, items, loot, XP or quest state. Rewards
  arrive as grant requests with a unique ID and are applied in one transaction, so a retry
  cannot duplicate them (ARCHITECTURE.md D5, DATABASE.md).
- **Security.** Read `SECURITY.md` before touching auth, sessions, economy or deployment.
  Passwords use Argon2id only; no secrets in Git; `.env.example` holds placeholders.
- **Endpoints** get authorisation and validation tests, with size and rate limits.
- **Checks:** `npm run typecheck` and `TEST_DATABASE_URL=... npm test`.
