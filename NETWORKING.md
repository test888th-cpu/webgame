# Networking (design — implementation starts in Milestone 3)

Nothing in this document is implemented yet, except `BuildInfo.PROTOCOL_VERSION = 1` in
the client.

## Transport
- **WSS** from browser to zone server; TLS terminates at a reverse proxy. HTTPS JSON to the
  API.
- One WebSocket per player per zone instance. Binary frames only.
- Godot `WebSocketPeer` with explicit message types. The high-level multiplayer RPC system
  is not used (ARCHITECTURE.md D4).

## Messages (v1 sketch)
Every frame is `u8 type | u16 length | payload`, with a maximum frame of **1 KiB from
client** and 16 KiB from server.

| Dir | Type | Payload |
|---|---|---|
| C→S | `Hello` | protocol version, join ticket |
| C→S | `Input` | seq u32, tick u32, buttons u16, move x/y i8 (−127..127) |
| C→S | `Action` | seq, action id (attack/skill/interact), target hint |
| S→C | `Welcome` | entity id, tick, zone snapshot |
| S→C | `Snapshot` | tick, last processed input seq, delta-compressed entity states in interest |
| S→C | `Event` | hit, death, loot-offer, quest-update (server-decided) |
| S→C | `Kick` | reason code |

The client sends **intent** only: buttons and a direction. Damage, hits, drops and
currency are never in a client message.

## Simulation and timing (initial targets, to be measured)
- Zone server simulation at 20 Hz, snapshots at 20 Hz in combat zones and 10 Hz in hubs.
- Local hero: client-side prediction with the shared `sim/` rules, then reconciliation
  against `last processed input seq`.
- Remote entities: interpolated ~100 ms behind.
- Combat is PvE. Hits resolve on the server's current state, so no lag-compensated rewind
  is needed. The client plays attack animations immediately as cosmetic prediction.

## Interest management
Uniform grid per instance (cell ≈ one screen width). A player receives entities in their
own cell and the neighbouring cells. Monsters outside every player's interest do not run AI.

## Validation and limits
- Per connection: at most 30 `Input` + 10 `Action` messages per second (token bucket).
  Unknown types or oversize frames disconnect the client.
- Server re-derives movement through `LaneMovement`. Input outside −127..127 is clamped;
  the speed cap is enforced by the rules themselves (see unit tests).
- Actions are checked against cooldowns, resources, range and state on the server.
- Rate-limit violations and protocol errors are written to the structured security log.

## Lifecycle
- **Reconnect:** a 30 s grace period keeps the hero in the instance. The client fetches a
  new ticket and resumes.
- **Session expiry:** tickets last 30 s and are single use. Access tokens are short lived.
- **Graceful shutdown:** the server drains (refuses new joins), checkpoints heroes, sends
  `Kick{server_restart}` and the client re-queues.
- **Crash:** reward grants are idempotent (DATABASE.md), so replays after a crash do not
  duplicate anything. At most the time since the last checkpoint is lost (position/HP only).
