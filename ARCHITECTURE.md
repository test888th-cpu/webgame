# Architecture

Status key: **[built]** exists and is tested · **[planned M#]** designed, not implemented.

## 1. Overview

```
 Browser (Godot web export, WebGL 2, single-threaded)
   │  HTTPS (REST/JSON)                  │  WSS (binary messages)
   ▼                                     ▼
 ┌───────────────────┐   join tickets  ┌──────────────────────────┐
 │ API service       │ ───────────────▶│ Zone servers             │
 │ Node 24 + Fastify │◀─────────────── │ Godot 4.7.2 headless     │
 │ stateless, N pods │  grants (idem-  │ one process per zone     │
 └────────┬──────────┘  potent, signed)│ instance, 20 Hz sim      │
          │ SQL (private network only)  └──────────────────────────┘
          ▼
   PostgreSQL 16 (primary + PITR backups)      Redis: not used until justified (§6)

 Static hosting/CDN (GitHub Pages first) serves the web client only.
```

| Component | Status | Responsibility |
|---|---|---|
| Web client (`client/`) | **[built]** test zone | Rendering, input, prediction and interpolation; never authoritative |
| Shared rules (`client/sim/`) | **[built]** movement, combat, AI, loot, quests, saves | Deterministic rules used by both client and zone server |
| API service (`backend/`) | **[built]** health and migrations; **[planned M3]** auth | Accounts, sessions, heroes, inventory, economy ledger, quests, zone allocation |
| Zone server | **[planned M3]** | Authoritative real-time simulation of one zone instance |
| PostgreSQL | **[built]** schema v1 | Durable state; the only source of truth for progression |
| CI/CD | **[built]** | Lint, tests, web export, browser smoke test, scans, SBOM, Pages deploy (gated) |

## 2. Key decisions

### D1. Godot 4.7.2, GDScript, Compatibility renderer, single-threaded web export
- 4.7.2 is the newest stable patch release. It was verified by running the editor
  headless, exporting, and loading the export in Chromium.
- WebGL 2 supports only the Compatibility renderer.
- The single-threaded export runs on any static host without COOP/COEP headers (see
  WEB_EXPORT.md). Trade-off: no worker threads, so CPU-heavy work stays on the main thread.
  This is acceptable because the client does not simulate the world.

### D2. Zone servers are a headless export of the same Godot project
The combat rules must run identically for client-side prediction and for server authority.
Three options were evaluated:

| Option | For | Against |
|---|---|---|
| **Godot headless zone server (chosen)** | One rules codebase (`sim/`), so prediction matches authority; GDScript only | Per-process memory and CPU are unmeasured (risk R1); GDScript is slower than Go or Rust |
| Node/TypeScript zone server | Same runtime as the API; cheap processes | Rules duplicated in two languages, so prediction drifts and every change is made twice |
| Nakama (Apache-2.0) authoritative matches | Mature accounts, social and matchmaking | Match logic in Go, Lua or TS (same duplication); JSON storage weakens relational economy constraints |

Mitigation for R1: Milestone 3 measures a headless instance (idle memory, CPU per player and
per monster). If one-process-per-instance is too costly, a single process can host several
instances. `sim/` is kept free of the scene tree and physics engine so it can run cheaply in
both places.

### D3. Separate stateless API service: Node.js 24 LTS + TypeScript + Fastify + pg
- Accounts, economy and persistence change rarely compared with the simulation, and need
  strict transactions, so they live in a small HTTP service that scales horizontally.
- Node 24 "Krypton" was chosen after checking the official release schedule on 2026-10-23.
  It is LTS (maintenance phase) with support until 2028-04-30, and 24.22.1 is the
  2026-10-20 security release. Node 26 becomes LTS on 2026-10-28; the upgrade will be
  evaluated after that and tested in staging. Node 22 support ends 2027-04-30.
- Node runs `.ts` directly (type stripping), so there is no build step or source maps.
  `tsc --noEmit` typechecks.
- Dependencies are deliberately few: `fastify` and `pg`. Argon2 (`@node-rs/argon2`), schema
  validation and JWT/ticket signing arrive with auth in M3, each justified in the PR.

### D4. Transport: WebSocket (WSS) with a custom binary protocol
- Browsers support WebSocket everywhere. WebRTC data channels would allow unreliable
  delivery but need signalling and TURN infrastructure. Revisit only if measured
  head-of-line blocking hurts gameplay.
- Godot's high-level multiplayer RPC is **not** used for gameplay. Explicit message schemas
  make validation, size limits, rate limits and protocol versioning reviewable.
  See NETWORKING.md.
- TLS terminates at a reverse proxy (Caddy or nginx) in front of the zone servers.

### D5. Persistence strategy
- Zone servers hold only temporary state (positions, HP, cooldowns, AI).
- Valuable outcomes (loot, XP, currency, quest steps) become **grant requests** with a
  server-generated UUID. The API applies each one in a single transaction with a unique
  constraint on the grant ID, so retries after crashes cannot duplicate rewards.
- Position and HP are checkpointed periodically and on zone exit, never every frame.
  See DATABASE.md.

### D6. Interest management and zone instances
- The world is split into zones; each zone may run several instances, each with a cap (see
  PERFORMANCE.md).
- Within an instance, a uniform spatial grid limits replication to entities within the
  viewer's area of interest.
- AI runs only for monsters near players. Spawners outside interest stay dormant.

### D7. Auto battle is a player, not a cheat
- `client/sim/AutoPilot.gd` decides the hero's input from the zone each tick: it presses
  the same buttons as a player (a `FighterInput`) and eats through `ZoneSim.use_item`.
  It never writes simulation state. A zone server therefore sees ordinary input and
  validates it like any other, and the client stays non-authoritative.
- `client/sim/AutoRules.gd` decides where auto may run (areas already beaten by hand) and
  when the farm loop rests. Both are pure and deterministic, like the rest of `sim/`.
- `client/scenes/game/AutoBattle.gd` is presentation glue. It owns the switch and the
  player's override (any input of their own wins that tick). It runs the farm loop
  through the same actions a player has: recall home, the shop and the taxi fare.

### D8. The world boss is a clock and a shared pool, decided in `sim/`
- `client/sim/WorldBossRules.gd` numbers rounds from the Unix epoch, which keeps every
  client and the future server on the same round. It also sizes the round's pool and
  pays reward tiers. `client/sim/WorldBossRun.gd` runs one attempt against what is left
  of the pool. Both are pure, with the time passed in.
- Today the pool belongs to the player and lives in the save (version 7). At IL-7 the
  zone server keeps one pool per round for everyone and pays tiers from the damage it
  saw, using the same rules. The client clock and client damage are never trusted for
  rewards online (CLAUDE.md).

## 3. Join flow [planned M3]

1. Client → API: log in, receive a short-lived access token and a rotating refresh token.
2. Client → API: request to enter a zone. The API picks or starts an instance and returns
   `{wss_url, ticket}`. The ticket is signed (Ed25519), expires in 30 s, is single use, and
   is bound to account, hero and instance.
3. Client → zone server: `Hello{protocol, ticket}`. The zone server verifies the signature
   offline, rejects replayed ticket IDs, and loads the hero snapshot from the API.
4. On disconnect the hero stays in the instance for a 30 s grace period. A new ticket for
   the same instance resumes the session.

## 4. Code boundaries

See CLAUDE.md "Boundaries". In short: presentation → rules (`sim/`) ← zone simulation;
persistence lives only in `backend/`; content is data under `client/data/` (M2).

## 5. Environments

`dev` (docker compose, local or cloud), `staging`, `production`: separate databases,
secrets and hosts. See DEPLOYMENT.md.

## 6. Redis policy

Not introduced until one of these needs it: rate limits shared across several API replicas,
cross-zone presence or party pub/sub (M6), or matchmaking queues. Each needs an ADR entry
here first.

## 7. Decision log

| Date | Decision |
|---|---|
| 2026-10-23 | D1–D6 recorded. Node 22 → Node 24.22.1 after checking the release schedule. |
| 2026-10-27 | D7 recorded: auto battle produces player input only (`AutoPilot`, `AutoRules`). |
| 2026-10-27 | D8 recorded: the world boss runs on the clock with a per-round pool (`WorldBossRules`). |
