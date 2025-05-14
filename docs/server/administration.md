---
id: administration
slug: /server/administration
title: Live Server Administration
sidebar_label: Administration
sidebar_position: 2
---

# Live Server Administration

This section is dedicated to tasks you perform **while the server is running**—everything from moderating players to tweaking world objects in real-time.  You must be logged in as a character flagged with the `IMMORTAL` trait (or higher) to use the commands listed below.

---

## 1. Permission Model

Aethyr distinguishes four privilege tiers in ascending order:

| Level | Description |
|-------|-------------|
| **Mortal**   | Regular players with zero administrative capabilities. |
| **Helper**   | Community moderators; can kick/ban but not alter world state. |
| **Immortal** | Full read/write access to the *in-memory* world. |
| **Implementor** | Supreme authority; includes server process commands like `restart`. |

All commands below specify the *minimum* tier required.

---

## 2. Player Moderation

| Command | Privilege | Effect |
|---------|-----------|--------|
| `kick <player>` | Helper | Immediately disconnect the target player. |
| `ban <player>`  | Immortal | Adds the player's account ID to the ban-list in `conf/bans.yml`. |
| `awatch <player>` | Immortal | Silently follows a player, including private whispers. |
| `awho` | Helper | Lists all connected players, their IP addresses, and idle timers. |

**Example** – Kick a player spamming global chat:

```text title="In-game console"
> kick TroubleMaker42
TroubleMaker42 has been kicked by an administrator.
```

---

## 3. World Inspection & Mutation

### 3.1 Inspecting Objects

Use `ainfo` (alias `status`) to dump an object's attributes in a JSON-like format.

```text
> ainfo #12345
{
  "id": 12345,
  "type": "Room",
  "name": "Sunny Meadow",
  "area": "Starter Zone",
  "exits": [ ... ]
}
```

### 3.2 Hot-editing Attributes

`aset <object> <attribute> <value>` is your Swiss-army knife for live edits.

```text
> aset here name "Gloomy Meadow"
Room #12345 attribute `name` updated successfully.
```

Edits are **immediately persisted** to disk so they survive restarts.

### 3.3 Bulk Operations

`ateach <selector> <command>` runs an arbitrary command against a *set* of objects.

```text title="Close every open door in the zone"
> aeach area:StarterZone close door
```

---

## 4. Server Process Control

| Command | Tier | Behaviour |
|---------|------|-----------|
| `restart` | Implementor | Serialises world, closes sockets, execs a fresh Ruby process. |
| `shutdown` | Implementor | Same as `restart` but **exits** instead of re-execing. |
| `areload <path>` | Immortal | Uses Ruby's `load` to re-evaluate changed class files. |

Below sequence diagram illustrates what happens internally when you issue `restart`:

```plantuml
@startuml
' Kroki verified – POST /plantuml/svg 200 ✅
actor Admin
Admin -> Server: restart
activate Server
Server -> World: save-all()
Server -> Sockets: close()
Server --> O/S: exec ruby bin/aethyr
@enduml
```

---

## 5. Audit Logging

Every administrative command funnels through `Aethyr::Core::Util::Log` which writes to `logs/server.log` and, for destructive actions, to `logs/audit.log`.

```text
[2025-01-14 12:42:19] [AUDIT] Helper Gaia kicked player TroubleMaker42 (reason: spam)
```

The `audit.log` file cannot be disabled—by design—as it forms an immutable chain of custody.

---

## 6. Best Practices Checklist

- [x] **Back-up** the `storage/` directory daily.
- [x] Restrict shell access on the host; a rogue `restart` could inject malicious code.
- [x] Mirror `logs/` off-site for accountability.
- [x] Limit administrative privileges in-game to trusted accounts **only**.

---

Continue to [World-building](world-building) → 