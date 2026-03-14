# Aethyr Documentation (Detailed Spec)

## Overview

Aethyr is an open-source Multi-User Dungeon (MUD) framework and reference game written in Ruby. It provides a complete, extensible engine for building text-based multiplayer virtual worlds, along with a playable reference implementation that demonstrates the engine's capabilities. Aethyr connects players via raw TCP using the Telnet protocol and renders a full server-side Ncurses terminal interface with multiple windows, 256-color support, and adaptive layouts.

The project serves a dual purpose: as a **framework** for MUD developers who want to build their own games on a modern, well-architected Ruby foundation, and as a **reference game** with a default world, commands, NPCs, and systems that can be played immediately out of the box.

### Key Capabilities

- **Real-world terrain generation** from ESA WorldCover 10m satellite land-cover data via GDAL
- **Server-side Ncurses rendering** with 7 named windows and 4 adaptive layout tiers
- **120+ player commands** spanning movement, combat, communication, inventory, skills, and emotes
- **30+ administration commands** for live world building, object inspection, and server management
- **NPC scripting system** with `.rx` reaction files, tick-based scheduling, and probabilistic behavior
- **22-slot equipment system** with layered clothing, dual-wield support, and armor
- **In-game calendar** with accelerated time (1 real minute = 1 game hour), atmospheric messages, and day/night cycle
- **GDBM-backed persistence** with Marshal serialization and a dehydrate/rehydrate pattern for volatile state
- **Optional event sourcing** via the Sequent framework with ImmuDB or file-based backends
- **Extensible architecture** with self-registering command handlers, pluggable traits, and a clean extension directory structure
- **Hot-reload support** via the `areload` admin command for runtime class reloading
- **BDD-first testing** with 200+ Cucumber feature files and full integration test coverage
- **Docker deployment** with a single `docker compose up` command

### Standards and Protocols

Aethyr implements or integrates with the following network and MUD-industry standards:

| Standard | Purpose |
| :------- | :------ |
| **Telnet** (RFC 854) | Primary client-server transport protocol with full IAC command negotiation |
| **NAWS** (RFC 1073) | Negotiate About Window Size -- automatic terminal dimension detection |
| **TTYPE** (RFC 1091) | Terminal Type negotiation for capability detection |
| **MCCP** (MCCP2, option 86) | MUD Client Compression Protocol for zlib-compressed data streams |
| **MSSP** (option 70) | MUD Server Status Protocol for advertising server metadata to listing services |
| **LINEMODE** (RFC 1184) | Telnet linemode negotiation for input handling |
| **SGA** (RFC 858) | Suppress Go Ahead for character-at-a-time mode |

### Technology Stack

| Category | Components |
| :------- | :--------- |
| **Runtime** | Ruby >= 3.0, Bundler |
| **CLI** | Methadone (CLI framework), Ncurses (server-side terminal rendering) |
| **Concurrency** | concurrent-ruby (TimerTask for periodic jobs), Ruby threads, IO.select multiplexing |
| **Persistence** | GDBM (file-based hash tables), Marshal (Ruby object serialization) |
| **Event Sourcing** | Sequent (CQRS/ES framework), ImmuDB (tamper-evident database) |
| **Pub/Sub** | Wisper (in-process event bus) |
| **Geospatial** | GDAL (raster processing for world generation) |
| **Testing** | Cucumber/Gherkin (BDD), RSpec, SimpleCov, RuboCop, ruby-prof |
| **Documentation** | Docusaurus, YARD, Kroki (PlantUML diagrams) |
| **Deployment** | Docker, Docker Compose |

---

## Glossary

### World Model

Room
: A discrete location in the game world. Rooms contain exits, players, mobiles, and objects. Each room has a terrain type, optional flags, and belongs to an area. Rooms render a rich `look` description that lists all visible contents.

Exit
: A directional link between two rooms. Each exit has a destination room GOID, a direction (stored as `alt_names`), and a `peer` method that describes what can be seen through the exit.

Door
: A lockable, openable exit with bidirectional state synchronization. Two Door objects are connected together so that opening, closing, locking, or unlocking one side automatically updates the other.

Portal
: A special exit that is invisible in direction listings, supports multiple traversal actions (jump, climb, crawl, step), and provides customizable entrance, exit, and transit messages with pronoun substitution.

Area
: A grid-based container of rooms. Areas define shared terrain types and flags that are inherited by contained rooms. Areas render ASCII maps showing room layouts, exits, and entity positions.

Container
: A game object with an inventory. Containers propagate events and output to their contents. `GridContainer` extends Container with positional placement on a grid.

### Entities

GameObject
: The abstract base class for every persistent entity in the game world. Identified by a GOID, with a name, descriptions, article, sex, attributes, flags, and an extensible `Info` metadata bag.

LivingObject
: A game object with health, balance, equipment, and inventory. Base class for both Player and Mobile.

Player
: A human-controlled character. Manages a network connection, display preferences, skills, satiety, color settings, and broadcasts `:player_input` events to subscribed command handlers.

Mobile
: An NPC (non-player character). Extends LivingObject with the `Reacts` trait for scripted behavior and the `Respawns` trait for death/revival mechanics. Supports admin debug output redirection.

Prop
: A simple generic game object with no special properties. The most basic concrete object type.

Armor
: A wearable game object at layer 1 (over clothing) with defense statistics for slash, pierce, blunt, frost, and energy damage types.

Corpse
: A temporary game object created when a Mobile dies. Includes the `Expires` trait and auto-deletes after 600 seconds (10 minutes).

Scroll
: A readable and writable game object. Includes the `Readable` trait for the `read` command.

### Systems

Event
: An OpenStruct-based message object carrying a `type` (module name), `action` (method name), and `player` (originating entity), along with arbitrary additional fields. Events can be chained via `attach_event`.

Action
: A subclass of Event representing a game action. Actions are submitted to the Manager's priority queue and executed by the server's main loop.

Gary
: "Game ARraY" -- a thread-safe, Mutex-protected Hash-backed set of all in-memory game objects. Supports queries by GOID, name, generic name, alt names, and arbitrary attribute matching. Implements `Enumerable`.

CacheGary
: A lazy-loading extension of Gary that loads objects from storage on demand when accessed by GOID, reducing memory usage for large worlds.

Manager
: The central hub of the game engine. Owns all game objects (via Gary), the StorageMachine, EventHandler, Calendar, and the action priority queues. Acts as a Facade over all major subsystems. Exposed as the global `$manager`.

StorageMachine
: The GDBM-backed persistence layer. Serializes game objects via `Marshal.dump`/`Marshal.load` into class-named GDBM files indexed by GOID. Manages player name/password indices.

EventHandler
: The central event dispatch engine. Processes a thread-safe Queue of events using reflection-based module resolution: `Module.const_get(event.type).send(event.action, event, player, room)`.

PriorityQueue
: A Fibonacci heap implementation used for scheduling actions. The Manager maintains two queues: `@pending_actions` (ready to execute) and `@future_actions` (time-delayed).

### Traits

Reacts
: A mixin providing NPC scripting via `.rx` reaction files. Includes a Reactor engine for event-driven behavior, a TickActions scheduler for periodic actions, and a rich scripting API for movement, communication, and object manipulation.

Respawns
: A mixin enabling Mobile objects to respawn after death at a configurable rate and location.

HasInventory
: A mixin adding an `Inventory` (a capacity-limited Gary subclass) to any game object.

Openable
: A mixin for objects that can be opened, closed, locked, and unlocked. Supports key-based locking with admin overrides.

Position
: A mixin tracking a character's physical posture (sitting, standing, lying) relative to the ground or another object.

Lexicon
: A comprehensive English pronoun and grammatical reference system. Generates contextually correct pronouns based on gender, plurality, grammatical person, subjectivity, relation, and quantifier.

Wearable
: A mixin for equipment items. Defines a 5-tier layer system (0: accessories, 1: armor, 2: clothing, 3: underclothing, 4: skin) and a body position slot.

Readable
: A mixin making objects readable via the `read` command. Adds `readable_text` attribute and `"read"` to the object's action list.

Expires
: A mixin for objects that auto-delete after a configurable time period.

Sittable
: A mixin for objects that can be sat upon (chairs, benches). Tracks occupants with a configurable maximum occupancy.

News
: A mixin providing bulletin board functionality with GDBM-persisted posts, reply threading, and announcement support.

Location
: A mixin for objects representing physical locations. Provides terrain type inheritance from parent areas and flag inheritance with negation support.

### Identity and Persistence

GOID
: Game Object Identifier. A unique persistent identifier for every game object. Generated as a GUID by default, with configurable formats: standard GUID, hex code, 16-bit integer, 24-bit integer, or 32-bit integer.

Dehydrate
: The process of stripping volatile (non-serializable) instance variables from an object before Marshal serialization. Returns the volatile data as a Hash for later restoration.

Rehydrate
: The process of restoring volatile instance variables to an object after Marshal deserialization. Called with the saved volatile data Hash, or `nil` when loading from storage (which initializes fresh volatile state).

Publisher
: The base class for all persistent game objects. Includes Wisper pub/sub, the Hydration module, and the Marshaller module. Enables event broadcasting and controlled serialization.

Volatile
: A class-level declaration marking instance variables that should be excluded from serialization. Declared via `volatile :@var_name`. Managed by the Hydration module.

### Extension System

HandlerRegistry
: A singleton registry of all command handler classes. Handlers self-register at load time, and the registry wires them into the Manager via Wisper's `:object_added` subscription at startup.

CommandHandler
: The base class for input processing handlers. Auto-subscribes to new Player objects via the `object_added` class method. When a player types a command, the handler's `player_input` method is invoked via Wisper pub/sub.

InputHandler
: The minimal base handler class with a `@player` attribute and a `player_input` method that returns `false` by default.

Skill
: A named, leveled ability owned by an entity. Has an XP-based progression system where 10,000 XP equals one level. Skills are registered on Player objects and can be invoked via commands.

Flag
: A named modifier attached to rooms, areas, or objects. Flags support negation (one flag can cancel another) and inheritance from parent containers. The built-in element system defines 8 flags across 4 elements.

Reaction
: A scripted behavior defined in a `.rx` file. Each reaction has an action trigger, a boolean test expression, and a Ruby reaction body that returns a command string for the NPC to execute.

### Infrastructure

Display
: The server-side Ncurses terminal rendering engine. Creates a virtual terminal (`Ncurses.newterm`) over the client's TCP socket and manages 7 named windows with adaptive layout selection.

Window
: An Ncurses window abstraction managed by the Display. Each window handles scrolling, color rendering, and content buffering independently.

FormatState
: A hierarchical text formatting state with parent-chain inheritance. Manages foreground/background colors and text attributes (bold, dim, underline, blink, reverse, standout). Parses format strings like `"fg:red bg:black bold"`.

PlayerConnection
: The network-facing wrapper for a connected client. Includes the Login state machine and Editor module. Manages input buffering, pagination, display output, and the transition from login to gameplay.

TelnetScanner
: The telnet protocol handler. Processes IAC command sequences, negotiates options (LINEMODE, NAWS, ECHO, MSSP, MCCP, SGA, BINARY), and extracts NAWS window dimensions.

Calendar
: The in-game time system. Converts real UNIX time to accelerated game time (1 real minute = 1 game hour) and broadcasts atmospheric messages on time transitions.

ServerConfig
: The singleton configuration module. Reads and writes YAML configuration from `conf/config.yaml` and provides typed accessor methods for all server settings.

---

## CLI Interface

### Server Executable (`bin/aethyr`)

The primary entry point for launching an Aethyr game server.

**Synopsis:**

```
bin/aethyr [OPTIONS]
```

**Options:**

| Flag | Description |
| :--- | :---------- |
| `-v`, `--verbose` | Enable verbose logging; sets log level to `Logger::Ultimate` (maximum detail) |
| `--flag VALUE` | Set an arbitrary runtime flag accessible via `ServerConfig` |
| `--log-level LEVEL` | Override log level (supports runtime toggling via `USR1` signal) |
| `--version` | Display version and exit |
| `--help` | Display help and exit |

**Environment Variables:**

| Variable | Purpose |
| :------- | :------ |
| `AETHYR_CFG` | Path to an alternative configuration file |

**Config File:** `.aethyr.rc` (Methadone RC file, optional)

**Behavior:**

1. Parses CLI arguments via Methadone.
2. Loads `ServerConfig` from `conf/config.yaml`.
3. Sets `$VERBOSE` and `ServerConfig[:log_level]` based on the `--verbose` flag.
4. Calls `Aethyr::main`, which instantiates `Aethyr::Server.new(address, port)`.
5. The server enters its main event loop (see [Architecture: Threading Model](#threading-model)).

### Setup Utility (`bin/aethyr_setup`)

An interactive offline administration tool for initializing, resetting, and configuring an Aethyr server. Must be run while the server is stopped.

**Synopsis:**

```
bin/aethyr_setup
```

**Menu Options:**

| # | Option | Description |
| :- | :----- | :---------- |
| 1 | **Initial setup** | Runs storage reset followed by initial configuration prompts (admin name, port, address) |
| 2 | **Initialize/reset storage** | Destructively erases all data under `storage/`, recreates directory structure, initializes GDBM databases, generates the world using ESA WorldCover data, creates the tutorial helper NPC, and saves all objects |
| 3 | **Delete player** | Removes a player by name from all storage indices and object files |
| 4 | **Change password** | Updates a player's password with verification prompts |
| 5 | **Change GOID type** | Configures the identifier format: GUID (default), 16-bit integer, 24-bit integer, or 32-bit integer |
| 6 | **Configuration** | Interactive editor for all `ServerConfig` keys with type-aware value parsing |
| 7 | **Exit** | Exits the setup utility |

**World Generation:**

Option 2 invokes the `WorldCoverGenerator` which downloads ESA WorldCover GeoTIFF tiles, processes them via GDAL, and generates a world of interconnected rooms with terrain types derived from satellite land-cover classification. The generator also creates a tutorial helper NPC -- a "tall man with a very long beard" -- in the starting room, loaded with the `helper.rx` reaction script that provides an interactive tutorial for new administrators.

### Experiments Playground (`bin/aethyr_experiments`)

A REPL-like sandbox environment for experimenting with the game engine.

**Synopsis:**

```
bin/aethyr_experiments [ARGS]
```

**Behavior:**

Delegates to `Aethyr::Experiments::CLI.start(ARGV)`, which provides access to the `Sandbox` class. The Sandbox creates a privileged player, provides a command DSL (`command`, `every`, `wait_until_idle`), and schedules commands for execution via a `Concurrent::TimerTask` running at 100ms intervals.

---

## Player Commands

### Movement and Navigation

All directional commands move the player through an exit in the specified direction. Movement is blocked if the player is prone (sitting or lying down) or if the exit is closed/locked.

| Command | Aliases | Description |
| :------ | :------ | :---------- |
| `north` | `n` | Move north |
| `south` | `s` | Move south |
| `east` | `e` | Move east |
| `west` | `w` | Move west |
| `up` | `u` | Move up |
| `down` | `d` | Move down |
| `in` | | Enter through a portal or passage |
| `out` | | Exit through a portal or passage |
| `move <direction>` | `go <direction>` | Move in a named direction |
| `back` | | Return to the previously visited room |

#### Perception Commands

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `look` | `look [object]`, `l [object]` | Examine the room or a specific object. Without arguments, displays the full room description including exits, players, mobiles, and objects |
| `peer` | `peer <exit>` | Look through an exit to glimpse the destination room |
| `feel` | `feel [object]` | Touch an object or feel the room's atmosphere |
| `listen` | `listen [object]` | Listen to ambient sounds or a specific object |
| `smell` | `smell [object]` | Smell the room or a specific object |
| `taste` | `taste <object>` | Taste an object |
| `map` | | Display an ASCII map of the current area (requires the Map skill) |

### Communication

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `say` | `say <message>` | Speak aloud to everyone in the current room |
| `whisper` | `whisper <player> <message>` | Whisper to a nearby player (may be intercepted by others in the room) |
| `tell` | `tell <player> <message>` | Send a private message to any online player regardless of location |
| `reply` | `reply <message>` | Reply to the last player who sent a `tell` |

### Emotes

Aethyr includes 30+ expressive emotes. Each emote can be used without a target (self-directed) or with a target player/object. Emotes generate three message variants: one for the actor, one for the target, and one for other observers in the room.

| Emote | Description |
| :---- | :---------- |
| `agree` | Nod in agreement |
| `back` | Announce your return |
| `blush` | Blush with embarrassment |
| `bow` | Bow respectfully |
| `brb` | Announce you will be right back |
| `bye` | Wave goodbye |
| `cheer` | Cheer enthusiastically |
| `cry` | Cry or weep |
| `curtsey` | Perform a curtsey |
| `ew` | Express disgust |
| `frown` | Frown disapprovingly |
| `grin` | Grin widely |
| `hi` | Greet someone |
| `hug` | Hug someone |
| `huh` | Express confusion |
| `laugh` | Laugh aloud |
| `no` | Shake your head in disagreement |
| `pet` | Pet someone or something |
| `poke` | Poke someone |
| `ponder` | Think deeply |
| `shrug` | Shrug your shoulders |
| `sigh` | Sigh deeply |
| `skip` | Skip merrily |
| `smile` | Smile warmly |
| `snicker` | Snicker quietly |
| `wave` | Wave a greeting |
| `yawn` | Yawn tiredly |
| `yes` | Nod affirmatively |

### Inventory and Equipment

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `inventory` | `i` | Display all items in your inventory |
| `get` | `get <item>`, `take <item>` | Pick up an item from the room |
| `drop` | `drop <item>` | Drop an item from your inventory into the room |
| `put` | `put <item> in <container>` | Place an item into a container |
| `give` | `give <item> to <player>` | Give an item to another player |
| `fill` | `fill <container>` | Fill a container |
| `wear` | `wear <item> [position]` | Equip a wearable item at an optional body slot |
| `remove` | `remove <item>` | Unequip a worn item back to inventory |
| `wield` | `wield <item> [hand]` | Wield a weapon in the specified hand (left, right, or dual) |
| `unwield` | `unwield [hand]` | Stop wielding a weapon |

### Combat

Combat in Aethyr uses a balance-based system. Characters must have balance to perform combat actions. Taking or dealing damage can affect balance.

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `kick` | `kick <target>` | Kick an opponent (requires the Kick skill) |
| `punch` | `punch <target>` | Punch an opponent |
| `slash` | `slash <target>` | Slash an opponent with a wielded weapon |
| `simple_block` | `simple_block` | Attempt a simple block against incoming attacks |
| `simple_dodge` | `simple_dodge` | Attempt to dodge incoming attacks |

**Damage Types:**

| Type | Description |
| :--- | :---------- |
| `:health` | Standard health damage, reduces HP |
| `:stamina` | Stamina damage, affects action capacity |
| `:fortitude` | Fortitude damage, affects resilience |

**Health Descriptors:**

The `health` command returns a descriptive string based on the player's current HP as a percentage of maximum:

| HP % | Description |
| :--- | :---------- |
| 0 | "dead" |
| 1-10 | "barely alive" |
| 11-20 | "nearly dead" |
| 21-30 | "very badly hurt" |
| 31-40 | "badly hurt" |
| 41-50 | "hurting" |
| 51-60 | "slightly hurt" |
| 61-70 | "a few scratches" |
| 71-80 | "a few bruises" |
| 81-90 | "feeling fine" |
| 91-99 | "in great shape" |
| 100 | "at full health" |

### Information and Utility

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `who` | | List all online players |
| `time` | | Display the current in-game time |
| `date` | | Display the current in-game date |
| `health` | | Display your current health as a descriptive string |
| `satiety` | | Display your current hunger level as a descriptive string |
| `skills` | | List your skills with levels and XP |
| `status` | | Display your overall character status |
| `help` | `help [topic]` | Display help for a topic, or list all topics |

**Satiety Descriptors:**

| Satiety % | Description |
| :-------- | :---------- |
| 0 | "literally dying of hunger" |
| 1-10 | "starving to death" |
| 11-20 | "ravenous" |
| 21-30 | "famished" |
| 31-40 | "very hungry" |
| 41-50 | "feeling hungry" |
| 51-60 | "could eat" |
| 61-70 | "feeling satisfied" |
| 71-80 | "not hungry" |
| 81-90 | "sated" |
| 91-100 | "full" |
| 101-110 | "very full" |
| 111-120 | "completely stuffed" |

### Player Settings

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `set` | `set <option> <value>` | Configure a player setting |
| `setcolor` | `setcolor <category> <color>` | Override a semantic color mapping |
| `showcolors` | | Display current color configuration |
| `setpassword` | `setpassword` | Change your password (prompts for old and new) |
| `gait` | `gait [description]` | Set your movement style description |
| `pose` | `pose [description]` | Set your idle pose description |
| `sit` | `sit [object]` | Sit down (on the ground or on an object) |
| `stand` | `stand` | Stand up |
| `more` | | View the next page of paginated output |
| `write` | `write [on object]` | Open the in-game text editor to write on an object |

### News System

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `write_post` | `write_post <board>` | Compose a new post on a news board (opens the editor) |
| `read_post` | `read_post <board> <id>` | Read a specific post by ID |
| `delete_post` | `delete_post <board> <id>` | Delete a post you authored |
| `list_unread` | `list_unread <board>` | List unread posts on a board |
| `latest_news` | `latest_news <board>` | Show the most recent posts in a threaded tree view |

### Meta Commands

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `quit` | | Disconnect from the server (character is saved automatically) |
| `deleteme` | | Permanently delete your character (requires confirmation) |
| `issue` | `issue <type> <description>` | Report a bug, idea, or typo (type: `bug`, `idea`, `typo`) |

---

## Administration Commands

Administration commands are prefixed with `a` and require elevated privileges. The admin user is defined in `ServerConfig[:admin]`.

### World Building

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `acarea` | `acarea <name>` | Create a new area |
| `acroom` | `acroom <name>` | Create a new room in the current area |
| `acexit` | `acexit <direction> <destination>` | Create an exit from the current room |
| `acdoor` | `acdoor <direction> <destination>` | Create a lockable door exit |
| `acportal` | `acportal <name> <destination>` | Create a portal to a destination |
| `acprop` | `acprop <name>` | Create a simple prop object |
| `acreate` | `acreate <type> <name>` | Create an object of any registered type |
| `adelete` | `adelete <object>` | Permanently delete a game object and its contents |

### Object Manipulation

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `adesc` | `adesc <object> <description>` | Set an object's long description |
| `ainfo` | `ainfo <object>` | Display the Info metadata of an object |
| `aset` | `aset <object> <attribute> <value>` | Set an instance variable on a game object (immediately persisted) |
| `aput` | `aput <object> in <container>` | Move an object into a container |
| `ahide` | `ahide <object>` | Toggle an object's visibility |
| `aforce` | `aforce <player> <command>` | Force a player to execute a command |
| `acomment` | `acomment <object> <text>` | Add an admin comment to an object |

### Inspection and Monitoring

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `alist` | `alist [type]` | List all objects, optionally filtered by type |
| `alook` | `alook <object>` | Detailed admin inspection of an object's attributes |
| `astatus` | `astatus <object>` | Display object status including GOID, class, container, and info dump |
| `awho` | `awho` | List all connected players with connection details |
| `awatch` | `awatch <player>` | Silently follow a player and intercept their communications |
| `alog` | `alog [lines]` | Display recent server log entries |
| `areas` | `areas` | List all areas in the game |

### System Management

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `aconfig` | `aconfig [key] [value]` | View or modify server configuration at runtime |
| `areload` | `areload [path]` | Hot-reload Ruby source files without restarting the server |
| `asave` | `asave` | Force an immediate save of all game objects |
| `restart` | `restart` | Graceful server restart: saves world, disconnects clients, re-execs |
| `terrain` | `terrain <room> <type>` | Set the terrain type of a room |
| `deleteplayer` | `deleteplayer <name>` | Permanently delete a player character and all their possessions |

### Teaching and Skills

| Command | Syntax | Description |
| :------ | :----- | :---------- |
| `alearn` | `alearn <skill>` | Learn a skill (admin self-teaching) |
| `ateach` | `ateach <player> <skill>` | Teach a skill to a player |
| `ahelp` | `ahelp [topic]` | Display admin help topics |

---

## Core Concepts

### Game Objects

Every entity in the Aethyr game world inherits from `GameObject`, which provides a common identity, description, containment, attribute, flag, and metadata system.

#### GameObject Data Model

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@game_object_id` | String | Auto-generated GUID | Unique persistent identifier (GOID). Generated via `Guid.new.to_s` with collision checking against `$manager.existing_goid?` |
| `@container` | String (GOID) | `nil` | GOID of the containing object (room, inventory, equipment) |
| `@name` | String | `nil` | Proper display name; falls back to `"#{@article} #{@generic}"` if nil |
| `@alt_names` | Array\<String\> | `[]` | Alternative names for matching player input |
| `@short_desc` | String | `nil` | One-line description shown in room listings |
| `@long_desc` | String | `nil` | Full description shown on `look`; falls back to `@short_desc` if blank |
| `@generic` | String | `nil` | Generic noun (e.g., "sword", "door", "corpse") |
| `@sex` | String | `nil` | Biological sex: `"m"` (masculine), `"f"` (feminine), `"n"` (neuter) |
| `@article` | String | `"a"` | Grammatical article ("a", "an", "the", "some") |
| `@show_in_look` | String/false | `nil` | If truthy, appended to the room description in `look` output |
| `@quantity` | Integer | `1` | Stack count for stackable objects |
| `@movable` | Boolean | `true` | Whether the object can be picked up |
| `@pose` | String | `nil` | Current pose description shown in room listings |
| `@busy` | Boolean | `false` | Reentrancy guard for the `update` method |
| `@actions` | Set | `Set.new` | Set of available action names |
| `@admin` | Boolean | `false` | Whether this object has admin privileges |
| `@attributes` | Hash\<Class, Object\> | `{}` | Pluggable attribute components keyed by class |
| `@info` | Info (OpenStruct) | `Info.new` | Extensible metadata bag with nested key access (`info.terrain.type`) |
| `@visible` | Boolean | `true` | Whether the object is visible (via `Defaults`) |
| `@gender` | Symbol | Derived from `@sex` | `:Masculine`, `:Feminine`, or `:Neuter` (via `Defaults`) |

#### Identity

Each game object is uniquely identified by its GOID. The GOID format is configurable via `ServerConfig[:goid_type]`:

| Format | Example | Description |
| :----- | :------ | :---------- |
| GUID (default) | `f47ac10b-58cc-4372-a567-0e02b2c3d479` | Standard 128-bit UUID with dashes |
| `:hex_code` | `f47ac10b58cc4372a5670e02b2c3d479` | 32-character hex string without dashes |
| `:integer_16` | `42319` | 16-bit integer (0-65535) |
| `:integer_24` | `11496230` | 24-bit integer (0-16777215) |
| `:integer_32` | `2943827561` | 32-bit integer (0-4294967295) |

GOID generation includes a collision-avoidance loop that regenerates if the ID already exists in `$manager`.

#### Attributes System

The `@attributes` hash provides a pluggable component system. Attributes are attached and detached at runtime:

- `attach_attribute(attribute)` -- Adds an attribute keyed by its class.
- `detach_attribute(attribute)` -- Removes an attribute by its class.
- Attributes can be queried: `@attributes[Blind]` returns the Blind attribute instance or nil.

Built-in attribute: `Blind` -- when attached, the entity cannot see.

#### Info System

The `Info` class extends `OpenStruct` with nested key access:

- `info.get("terrain.type")` -- Dot-notation access to nested values.
- `info.set("terrain.type", :grassland)` -- Dot-notation assignment.
- `info.delete("terrain.type")` -- Dot-notation deletion.

Info is used extensively for storing metadata that does not warrant a dedicated instance variable: terrain data, respawn settings, board names, death messages, skill data, explored rooms, and more.

#### Flags System

Flags are modifiers applied to game objects (primarily rooms and areas). Each `Flag` has:

| Field | Type | Description |
| :---- | :--- | :---------- |
| `affected` | Object | What the flag affects |
| `id` | Symbol | Unique identifier (e.g., `:plus_fire`) |
| `name` | String | Display name (e.g., `"+fire"`) |
| `affect_desc` | String | Description text (e.g., "so hot it is hard to breathe") |
| `help_desc` | String | Tooltip/help text |
| `flags_to_negate` | Array\<Symbol\> | Flags this flag cancels (e.g., `:plus_fire` negates `:minus_fire`) |

The built-in element system defines 8 flags across 4 elements:

| Flag | ID | Opposes | Description |
| :--- | :- | :------ | :---------- |
| `PlusWater` | `:plus_water` | `:minus_water` | "humid and wet" |
| `MinusWater` | `:minus_water` | `:plus_water` | "dry and arid" |
| `PlusEarth` | `:plus_earth` | `:minus_earth` | "alive and growing" |
| `MinusEarth` | `:minus_earth` | `:plus_earth` | "barren, covered in dust" |
| `PlusFire` | `:plus_fire` | `:minus_fire` | "so hot it is hard to breathe" |
| `MinusFire` | `:minus_fire` | `:plus_fire` | "deathly cold, breath freezes" |
| `PlusAir` | `:plus_air` | `:minus_air` | "fresh with an inviting breeze" |
| `MinusAir` | `:minus_air` | `:plus_air` | "stale and stagnant" |

Flags inherit from parent areas to child rooms. A room can negate an inherited flag by attaching the opposing flag.

#### Defaults System

The `Defaults` module provides class-level declarative default values:

```ruby
default(:gender) { |this| ... }  # Derives gender from @sex
default(:visible) { true }
```

`load_defaults` is called in `initialize` and iterates the `@@defaults` hash (keyed by class), setting instance variables that are not already defined. This allows subclasses to declare defaults without overriding constructors.

#### Equality Semantics

`GameObject#==` supports comparison against multiple types:

1. **String matching GOID** -- `object == "some-goid-string"` returns true if the GOID matches.
2. **String matching name** -- case-insensitive match against `@name`.
3. **String matching alt_names** -- case-insensitive match against any alternative name.
4. **Class comparison** -- `object == Room` returns true if the object is a Room instance.

#### Method Missing Behavior

`GameObject#method_missing` logs the missing method call and returns `nil` instead of raising `NoMethodError`. This Null Object pattern ensures that unhandled messages do not crash the game, at the cost of silently swallowing typos.

### Rooms and Navigation

#### Room Data Model

`Room` inherits from `Container` (which includes `HasInventory`) and mixes in the `Location` trait.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@generic` | String | `"room"` | Always "room" |
| `info.terrain.indoors` | Boolean | `false` | Whether the room is indoors |
| `info.terrain.water` | Boolean | `false` | Whether the room contains water |
| `info.terrain.underwater` | Boolean | `false` | Whether the room is underwater |
| `info.terrain.room_type` | Symbol | `nil` | Terrain classification symbol |

**Key Methods:**

- `exit(direction)` -- Finds an Exit in the room's inventory matching the given direction (checked against `alt_names`).
- `exits(only_visible=true)` -- Returns all Exit objects, optionally filtering invisible ones.
- `players(only_visible=true, exclude=nil)` -- Returns Player instances in the room.
- `mobiles(only_visible=true, exclude=nil)` -- Returns non-Player living objects.
- `things(only_visible=true)` -- Returns non-living, non-Exit visible objects.
- `look(player)` -- Renders the complete room description as a formatted string.

**Look Output Structure:**

The `look` method produces output in the following order:

1. Room title in `<roomtitle>` tags
2. Short description text
3. `show_in_look` text from objects with that attribute
4. Exits list with open/closed state indicators
5. Terrain type and visible flag descriptions
6. Player list with poses and short descriptions
7. Mobile list with identifier tags
8. Object/item list with identifier tags and poses

#### Exit Data Model

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@exit_room` | String (GOID) | `nil` | Destination room GOID |
| `@generic` | String | `"exit"` | Always "exit" |
| `@article` | String | `"an"` | Grammatical article |
| `@alt_names` | Array | `["[Needs name]"]` | Direction aliases (e.g., `["e", "east"]`) |

The `peer` method looks through the exit. If `@exit_room` is set and the destination room exists, it returns "Squinting slightly, you can see [room name]." Otherwise it returns a darkness or dead-end message.

#### Door Data Model

`Door` extends `Exit` with the `Openable` trait.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@connected_to` | String (GOID) | `nil` | GOID of the matching door on the other side |
| `@lockable` | Boolean | `true` | Whether the door supports locking |
| `@keys` | Array\<String\> | `[]` | GOIDs of key objects that can lock/unlock this door |
| `@open` | Boolean | `false` | Current open/closed state |
| `@locked` | Boolean | `false` | Current locked/unlocked state |

**Bidirectional Synchronization:**

When a Door is opened, closed, locked, or unlocked, the change is automatically propagated to the `@connected_to` door:

- `open(event)` -> calls `other_side.other_side_opened`
- `close(event)` -> calls `other_side.other_side_closed`
- `lock(key)` -> calls `other_side.lock(key)`
- `unlock(key)` -> calls `other_side.unlock(key)`

`connect_to(door)` establishes the bidirectional link. When passed a Door object, it connects both sides and synchronizes the open state. When passed a GOID string, it creates a one-way connection.

#### Portal Data Model

`Portal` extends `Exit` with invisible navigation and customizable messages.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@visible` | Boolean | `false` | Portals do not appear in exit listings |
| `@show_in_look` | String | `"A portal to the unknown stands here."` | Shown in room description text |

Portals support four traversal actions with distinct message sets:

| Action | Entrance (to destination) | Exit (from origin) | Transit (to traveler) |
| :----- | :------------------------ | :------------------ | :-------------------- |
| `jump` | "jumps in over" | "jumps over" | "Gathering your strength, you jump over" |
| `climb` | "comes in, climbing" | "climbs" | "You reach up and climb" |
| `crawl` | "crawls in through" | "crawls out through" | "You stretch out on your stomach and crawl through" |
| default | "steps through" | "steps through and vanishes" | "You boldly step through" |

All portal messages support `!name`, `!pronoun`, and `!pronoun(:possessive)` substitution for grammatically correct third-person narration.

#### Area System

`Area` extends `GridContainer` with the `Location` trait and a configurable map renderer.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@map_type` | Symbol | `:rooms` | Map rendering mode: `:rooms`, `:world`, or `:none` |

**Map Rendering:**

- `:rooms` mode renders a detailed ASCII map with box-drawing characters (`┼`, `├`, `┬`), directional arrows (`↑`, `↓`, `↕`, `←`, `→`, `↔`), and symbols for players (`☺`), mobs (`*`), and merchants (`☻`).
- `:world` mode renders a simpler overview with `"░"` for rooms and `"☺"` for the player.
- `:none` disables map rendering.

#### Terrain Types

The built-in terrain types are:

| Constant | Room Text | Area Text |
| :------- | :-------- | :-------- |
| `GRASSLAND` | "grasslands" | "waving grasslands" |
| `UNDERGROUND` | "underground" | "underground caverns" |
| `CITY` | "city" | "city streets" |
| `TOWN` | "town" | "small town roads" |
| `TUNDRA` | "tundra" | "icy plains" |

Terrain types are inherited from parent areas via the `Location` trait. A room's `terrain_type` falls back to `parent_area.terrain_type` if not explicitly set.

### Living Entities

#### LivingObject Data Model

`LivingObject` extends `GameObject` with `Position` and `HasInventory`.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@equipment` | Equipment | new Equipment | Wearable/wielded item management |
| `@balance` | Boolean | `true` | Combat balance state |
| `@alive` | Boolean | `true` | Living/dead status |
| `@last_target` | Object | `nil` | Most recent combat target |
| `info.stats.health` | Integer | `100` | Current hit points |
| `info.stats.max_health` | Integer | `100` | Maximum hit points |

**Damage Processing:**

`take_damage(amount, type)` reduces the appropriate stat. Supported types:

- `:health` -- Reduces `info.stats.health` (clamped to 0).
- `:stamina` -- Reduces `info.stats.stamina`.
- `:fortitude` -- Reduces `info.stats.fortitude`.

After processing, fires `Event.new(:Generic, action: :take_damage, ...)`.

#### Player

`Player` extends `LivingObject` with network connectivity, display preferences, skills, and satiety.

| Field | Type | Volatile? | Default | Description |
| :---- | :--- | :-------- | :------ | :---------- |
| `@player` | PlayerConnection | Yes | `nil` | Network I/O handle |
| `@help_library` | HelpLibrary | Yes | new HelpLibrary | Per-player help system |
| `@admin` | Boolean | No | `false` | Admin privilege flag |
| `@skills` | Hash | No | `{wield: 50, thrust: 50, simple_block: 50}` | Skill name -> level |
| `@last_target` | Object | No | `nil` | Last combat target |
| `@color_settings` | Hash | No | `nil` | Custom color overrides |
| `@use_color` | Boolean | No | `nil` | Color toggle |
| `@word_wrap` | Integer | No | `120` | Line wrap width |
| `@page_height` | Integer | No | `nil` | Pagination height |
| `@deaf` | Boolean | No | `false` | Deaf status |
| `@blind` | Boolean | No | `false` | Blind status |
| `@reply_to` | Object | No | `nil` | Last tell sender |
| `@layout` | Symbol | No | `:basic` | Display layout type |
| `info.stats.satiety` | Integer | No | `120` | Hunger level (0-120) |
| `info.skills` | Hash | No | `{Map, Kick}` | Skill objects |
| `info.explored_rooms` | Set | No | `Set.new` | Rooms the player has visited |

**Input Pipeline:**

When a player types a command, `handle_input(input)` broadcasts a `:player_input` event via Wisper. All subscribed `CommandHandler` instances receive this event and attempt to match the input against their patterns.

**Output Pipeline:**

`output(message, no_newline, message_type:, internal_clear:)` sends text through `@player.say(...)`. Arrays are joined with `\r\n`. If the connection fails, `quit` is called.

**Healing:**

The `run` method (called each game tick) heals the player by 10 HP per tick, up to `max_health`.

**Sensory Events:**

`out_event(event)` selects the appropriate message variant based on the player's role (target, actor, or observer) and sensory state (blind, deaf, or both). Events carry up to 8 message fields:

| Field | When Used |
| :---- | :-------- |
| `to_player` | Sent to the acting player |
| `to_target` | Sent to the target |
| `to_other` | Sent to other observers |
| `to_blind_target` | Sent to a blind target |
| `to_deaf_target` | Sent to a deaf target |
| `to_deafandblind_target` | Sent to a blind and deaf target |
| `to_blind_other` | Sent to blind observers |
| `to_deaf_other` | Sent to deaf observers |

#### Mobile (NPC)

`Mobile` extends `LivingObject` with `Reacts` and `Respawns`.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@short_desc` | String | Generic short description | NPC appearance text |
| `info.redirect_output_to` | String (GOID) | `nil` | Admin GOID to receive debug output |
| `info.respawn_area` | Object | Current container | Where to respawn |
| `info.respawn_rate` | Integer | `900` | Seconds between death and respawn |

**Admin Debug Redirect:**

When `info.redirect_output_to` is set to an admin player's GOID, all output and events the Mobile receives are forwarded to that admin (prefixed with `[mob_name sees: ...]`). This allows administrators to observe the game from an NPC's perspective.

**Balance Events:**

The Mobile's `balance=` setter fires an `:action => :balance` alert event before updating the value, enabling reaction scripts to respond to balance changes (e.g., an NPC that counterattacks when it regains balance).

### Inventory and Equipment

#### Inventory

`Inventory` extends `Gary` with capacity limits and grid-based positioning.

| Field | Type | Default | Description |
| :---- | :--- | :------ | :---------- |
| `@capacity` | Integer/nil | `nil` | Maximum items (nil = unlimited) |
| `@grid` | Hash | `{}` | Position -> game object mapping |

`add(game_object, position=nil)` checks capacity and slot conflicts before insertion. `marshal_dump` serializes as `[goid, position]` pairs for efficient persistence.

#### Equipment System

`Equipment` includes `HasInventory` and manages 22 body slots with layered equipment.

**Body Slots:**

| Slot | Slot | Slot |
| :--- | :--- | :--- |
| `:head` | `:face` | `:neck` |
| `:left_shoulder` | `:torso` | `:right_shoulder` |
| `:left_arm` | `:waist` | `:right_arm` |
| `:left_wrist` | | `:right_wrist` |
| `:left_hand` | | `:right_hand` |
| `:left_ring_finger` | | `:right_ring_finger` |
| `:left_ear` | | `:right_ear` |
| `:legs` | | |
| `:left_ankle` | | `:right_ankle` |
| `:left_foot` | | `:right_foot` |

**Layer System:**

| Layer | Purpose | Examples |
| :---- | :------ | :------- |
| 0 | Accessories / wielded items | Rings, weapons |
| 1 | Armor | Plate armor, chain mail |
| 2 | Regular clothing | Shirts, pants |
| 3 | Underclothing | Underwear |
| 4 | Skin / tattoos / scars | Permanent markings |

Higher-numbered layers are worn closer to the body. Equipment at the same slot and layer level conflicts.

**Dual-Wield Support:**

`check_wield(item, position)` validates wielding constraints:
- Left hand: `check_wield(item, "left")` -- fails if occupied.
- Right hand: `check_wield(item, "right")` -- fails if occupied.
- Dual: `check_wield(item, "dual")` -- requires both hands empty.
- Default: assigns to the first empty hand.

### Event System

#### Event Data Model

`Event` extends `OpenStruct` and carries arbitrary data between system components.

**Required Fields:**

| Field | Type | Description |
| :---- | :--- | :---------- |
| `type` | Symbol | Module name that handles this event (e.g., `:Combat`, `:Communication`) |
| `action` | Symbol | Method name to invoke (e.g., `:say`, `:kick`) |
| `player` | GameObject | The entity the event concerns |

**Common Optional Fields:**

`at`, `target`, `object`, `to`, `to_player`, `to_target`, `to_other`, `to_blind_target`, `to_deaf_target`, `to_deafandblind_target`, `to_blind_other`, `to_deaf_other`, `message_type`

**Event Chaining:**

`attach_event(event)` chains a sub-event that executes immediately after the parent. The EventHandler recursively collects all attached events via `get_attached(event)`.

**Merge Operator:**

`event << hash` merges additional fields into an existing event. Handles Ruby 3.3+ compatibility by defining singleton reader/writer methods if `OpenStruct#new_ostruct_member` is unavailable.

#### EventHandler Dispatch

The `EventHandler` processes events from a thread-safe Queue:

1. Validates the event is an `Event` instance.
2. Collects all attached sub-events recursively.
3. For each event:
   - Resolves the player and room from `$manager`.
   - Substitutes `'me'` with the player's GOID in `at`, `object`, and `target` fields.
   - If `type` is `:Future`, delegates to `$manager.future_event`.
   - Otherwise, dispatches via reflection: `Module.const_get(e.type).send(e.action, e, player, room)`.

The reflection-based dispatch means any Ruby module whose name matches an event's `type` field will handle events of that type. New command modules are loaded dynamically via `require` without modifying the dispatcher.

#### Action Scheduling

The Manager maintains two priority queues:

- **`@pending_actions`** -- Actions ready for immediate execution. The server's main loop calls `pop_action` to dequeue the highest-priority action.
- **`@future_actions`** -- Time-delayed actions. Each entry has an activation timestamp. `pop_action` moves matured future actions to `@pending_actions` before dequeuing.

`submit_action(action, priority: 0, wait: nil)`:
- If `wait` is nil or 0: pushes to `@pending_actions`.
- If `wait > 0`: pushes to `@future_actions` with activation time = `epoch_now + wait`.

### Calendar and Time

The Calendar converts real UNIX timestamps to accelerated in-game time:

| Real-World Duration | In-Game Duration |
| :------------------ | :--------------- |
| 1 minute | 1 hour |
| 1 hour | 1 day |
| 24 hours | 24 days (1 month) |
| 12 days | 12 months (1 year) |

**Epoch:** March 20, 2008 UTC (`StartTime = 1205971200`).

**Month Names:** First, Second, Third, ..., Twelfth (12 months per year).

**Time of Day Descriptors:**

The `time_of_day` method maps the current game hour (0-59) to descriptive strings: "midnight", "grey dawn", "golden sunrise", "early morning", "mid-morning", "late morning", "noon", "early afternoon", "mid-afternoon", "late afternoon", "sunset", "dusk", "early night", "late night".

**Atmospheric Messages:**

The Calendar broadcasts atmospheric messages to all connected players at time transitions:

- Midnight: "An eerie feeling washes over you."
- Dawn: "The grey light of dawn begins to illuminate the world."
- Sunrise: "The sun rises over the horizon, bathing the world in golden light."
- Noon: "The sun reaches its zenith."
- Sunset: "The sun sets behind the horizon, painting the sky in red and orange."
- Starlight: "The stars begin to twinkle overhead."

**Day/Night:** Day spans hours 15-44 (approximately dawn to dusk). All other hours are night.

### Skills System

Skills have an XP-based progression system:

| Formula | Value |
| :------ | :---- |
| Level | `(xp / 10000) + 1` |
| XP per level | `10000` |
| XP to next level | `10000 - (xp % 10000)` |

**Built-in Skills:**

| Skill | ID | Description |
| :---- | :- | :---------- |
| Kick | `:kick` | "Kick your opponent where it hurts" |
| Map | `:map` | "Maps the layout and contents of an area" |

New players start with Map at 750 XP and Kick at 0 XP.

### Help System

Each Player has a dedicated `HelpLibrary` instance (volatile -- not persisted).

**HelpLibrary Operations:**

- `entry_register(entry)` -- Registers a help entry keyed by topic name.
- `search_topics(term)` -- Regex search across all topic names.
- `lookup_topic(topic)` -- Direct topic lookup.
- `render_topic(topic)` -- Renders a help entry, following redirect chains, displaying aliases, syntax formats, content, and "see also" links.

**Help File Format:**

Help entries are `.help` files stored in `lib/aethyr/core/help/` (player help) and `lib/aethyr/core/help/admin/` (admin help). The core distribution includes 60+ player help files and 30+ admin help files.

**Help Registration:**

Command handlers that include `HandleHelp` automatically register their help entries with each player they subscribe to. The `help_entries` constructor parameter accepts an array of `HelpEntry` objects.

---

## NPC Scripting (Reaction System)

### Reaction Files (.rx Format)

Reaction scripts are plain-text files with a `.rx` extension stored in `lib/aethyr/extensions/reactions/`. Each file contains one or more reaction blocks with three sections:

```
!action <event_action> [<additional_actions>...]
!test <ruby_expression>
!reaction <ruby_expression_returning_command_string>
```

**Section Descriptions:**

| Section | Purpose |
| :------ | :------ |
| `!action` | One or more event action symbols that trigger this reaction (e.g., `say`, `hi`, `say hi emote`) |
| `!test` | A Ruby expression evaluated as a boolean guard. Has access to `event` (the triggering Event) and `self` (the Mobile). Return truthy to proceed |
| `!reaction` | A Ruby expression that returns a command string for the NPC to execute (e.g., `"sayto #{event[:player].name} Hello!"`) |

**Example Reaction (from `helper.rx`):**

```
!action hi
!test true
!reaction "sayto #{event[:player].name} Hi there #{event[:player].name}! I am here to help you get started. Just say \"help\" if you need assistance."
```

### Reactor Engine

The `Reactor` class manages the reaction registry:

- `@reactions` -- Hash\<Symbol, Array\<reaction_hash\>\> where each reaction hash contains `:action`, `:test` (RProc), and `:reaction` (RProc).
- `load(file)` -- Parses `.rx` files into reaction hashes and registers them.
- `react_to(event)` -- Iterates all reactions matching `event.action`, evaluates each `:test` against the event, and collects command strings from reactions whose tests pass.
- `add(reaction)` -- Validates and registers a reaction hash. Converts string expressions to `RProc` (resumable/serializable Proc).

The Reactor supports multiple actions per reaction block (space-separated on the `!action` line), enabling a single reaction to respond to multiple event types.

### Tick Actions

The `Reacts` trait includes a tick-based scheduling system:

- `after_ticks(ticks, &block)` -- Schedules a one-shot action to execute after `ticks` game ticks.
- `every_ticks(ticks, &block)` -- Schedules a repeating action that fires every `ticks` game ticks.
- `run` -- Called each game tick. Decrements countdowns, fires due actions, and removes one-shots.

Each entry in `@tick_actions` is `[countdown, callable, repeat_interval]`. The `TickActions` class wraps an Array with custom `marshal_dump`/`marshal_load` that serialize as empty strings -- tick actions are intentionally not persisted across server restarts.

### Scripting API

The `Reacts` module provides a rich set of private helper methods available within reaction scripts:

**Movement:**
- `go(direction)` -- Move the NPC in a direction.
- `random_move(probability)` -- With the given probability, move to a random exit within the same area.

**Communication:**
- `say(output)` -- Speak aloud in the room.
- `sayto(target, output)` -- Speak directly to a target.
- `emote(string)` -- Perform a free-form emote.

**Object Manipulation:**
- `make_object(klass)` -- Create a new game object of the specified class.
- `delete_object(object)` -- Remove a game object from the world.

**Event Queries:**
- `said?(event, phrase)` -- Check if a phrase was spoken in the triggering event.
- `object_is_me?(event)` -- Check if the event's target is this NPC.

**Control Flow:**
- `random_act(*acts)` -- Randomly select and execute one action from a list.
- `with_prob(probability, action)` -- Execute an action with the given probability (0.0-1.0).
- `action_sequence(sequence, options)` -- Create a chain of attached events with configurable delays and looping.

**Following:**
- `follow(object, message)` -- Start following a game object, mirroring its movements.
- `unfollow(object, message)` -- Stop following.

**Manager Delegates:**
- `get_object(goid)` -- Look up a game object by GOID.
- `find(name, container)` -- Search for an object by name.

---

## Display and Rendering

### Server-Side Ncurses Architecture

Aethyr renders the game interface server-side using Ncurses. When a client connects, the server creates an Ncurses terminal directly over the TCP socket:

```ruby
@screen = Ncurses.newterm('xterm-256color', socket, socket)
```

This approach provides rich terminal rendering without requiring specialized MUD clients -- any terminal emulator that supports xterm-256color suffices. The server handles all cursor positioning, window management, and color rendering.

### Window System

The Display manages 7 named windows:

| Window | Purpose | Default Behavior |
| :----- | :------ | :--------------- |
| `:main` | Primary game output (room descriptions, combat, communication) | Always present; scrollable |
| `:input` | Player command input (3 lines tall, always at bottom) | Always present |
| `:map` | ASCII area map | Updated on room change |
| `:look` | Current room description | Updated on room change |
| `:quick_bar` | HP progress bar (Unicode block characters) | Updated each tick |
| `:status` | Character status information | Updated each tick |
| `:chat` | Dedicated communication channel | Communication messages routed here |

**Window Focus Cycling:**

The Tab key cycles focus between windows: input -> look -> map -> main -> chat -> status -> input. The focused window receives Page Up/Down scrolling commands.

### Layout Engine

The Display selects from 4 layout tiers based on the client's terminal dimensions (detected via NAWS telnet negotiation):

| Layout | Min Width | Min Height | Windows | Description |
| :----- | :-------- | :--------- | :------ | :---------- |
| `:wide` | 300 | 60 | All 7 | Full interface with all panels |
| `:full` | 249 | 60 | 6 | All except status window |
| `:partial` | 166 | 60 | 5 | Reduced layout |
| `:basic` | any | any | 2 | Just main output + input (fallback) |

The input window is always 3 lines tall and anchored to the bottom of the terminal. Other windows are arranged based on available space.

**Adaptive Resizing:**

When the client's terminal is resized (detected via NAWS), `resolution=(width, height)` calls `Ncurses.resizeterm` and triggers a full layout recalculation via `global_refresh`.

### Color System

Aethyr supports 256 colors with 23 semantic color categories. Each category has a default color that players can override.

**Default Color Mappings:**

| Category | Default | Description |
| :------- | :------ | :---------- |
| `roomtitle` | green bold | Room name in look output |
| `object` | blue | Objects/items in descriptions |
| `player` | cyan | Player names |
| `mob` | yellow bold | Mobile NPC names |
| `merchant` | yellow dim | Merchant NPC names |
| `exit` | green | Exit/direction names |
| `say` | white bold | Speech text |
| `tell` | cyan bold | Private message text |
| `important` | red bold | Important announcements |
| `identifier` | magenta bold | Object identifiers |
| `waterhigh` | blue | High water element |
| `waterlow` | blue dim | Low water element |
| `earthhigh` | green | High earth element |
| `earthlow` | green dim | Low earth element |
| `firehigh` | red | High fire element |
| `firelow` | red dim | Low fire element |
| `airhigh` | white | High air element |
| `airlow` | white dim | Low air element |

Players override colors using: `setcolor <category> <format_string>` where the format string is a space-separated list of properties (e.g., `"fg:red bg:black bold"`).

#### FormatState Hierarchy

`FormatState` implements a parent-chain inheritance model for text formatting:

- Each FormatState has an optional `@parent`.
- Properties (fg, bg, bold, dim, underline, blink, reverse, standout) fall back to the parent if not explicitly set.
- Root defaults: fg = white, bg = black, all attributes off.
- `apply(window)` activates the format on an Ncurses window.
- `revert(window)` restores the parent's formatting.

### Markup Language

The text rendering pipeline parses custom XML-like tags in output strings:

| Tag | Purpose | Color Default |
| :-- | :------ | :------------ |
| `<roomtitle>` | Room names | green bold |
| `<player>` | Player names | cyan |
| `<mob>` | Mobile NPC names | yellow bold |
| `<exit>` | Direction/exit names | green |
| `<object>` | Object/item names | blue |
| `<identifier>` | Object identifiers | magenta bold |
| `<important>` | Important messages | red bold |
| `<raw>` | Raw ANSI escape sequences (passed through) | N/A |
| `<waterhigh>`, `<waterlow>` | Water element descriptions | blue / blue dim |
| `<earthhigh>`, `<earthlow>` | Earth element descriptions | green / green dim |
| `<firehigh>`, `<firelow>` | Fire element descriptions | red / red dim |
| `<airhigh>`, `<airlow>` | Air element descriptions | white / white dim |

### Input Handling

**Keyboard:**

| Key | Action |
| :-- | :----- |
| Left/Right Arrow | Move cursor within input |
| Up/Down Arrow | Scroll the focused window |
| Page Up/Down | Scroll focused window by 5 lines |
| Tab | Cycle window focus |
| Enter | Submit input, echo to main window with `>>>>>` prefix |
| Backspace | Delete character before cursor |
| Escape sequences | VT100 arrow key emulation (e.g., `\e[A` = up) |

**Telnet Negotiation:**

The `TelnetScanner` processes IAC command sequences in a state machine:

1. **PREAMBLE** -- On connection, sends `DO LINEMODE`, `DO NAWS`, `WILL ECHO`, `DO MSSP`, `DO TTYPE`, `WILL SGA`, `WILL BINARY` negotiation sequences.
2. **WILL/WONT** -- Tracks client capabilities: NAWS, linemode, echo, MSSP.
3. **NAWS Subnegotiation** -- Extracts 4 bytes: low width, high width, low height, high height. Updates Display resolution.
4. **MSSP** -- Sends MUD Server Status Protocol data loaded from `conf/mssp.yaml` merged with dynamic values from `$manager` (player count, uptime, room/area counts, GOID count).

**Non-Blocking Read:**

The Display's `recv` method uses a multi-stage state machine (`@read_stage`):
1. `:none` -- Check for pending data.
2. `:update` -- Read telnet preamble responses.
3. `:iac` -- Process IAC commands.
4. `:input` -- Read player input from the input window.

### Progress Bars

The `generate_progress` class method renders Unicode block-character progress bars with 1/8th block precision using characters: `█`, `▉`, `▊`, `▋`, `▌`, `▍`, `▎`, `▏`. Used for HP display in the quick_bar window.

---

## Persistence and Storage

### GDBM Storage Architecture

All persistent data is stored in GDBM (GNU Database Manager) files under the `storage/` directory.

**File Layout:**

| File Path | Key Format | Value Format | Purpose |
| :-------- | :--------- | :----------- | :------ |
| `storage/goids` | GOID string | Class name string | GOID-to-class index |
| `storage/players` | Player name (downcased) | GOID string | Name-to-GOID index |
| `storage/passwords` | GOID string | MD5 hex digest | Password authentication |
| `storage/<ClassName>` | GOID string | Marshaled object bytes | Object data by class |
| `storage/boards/<goid>` | Post ID | Marshaled post hash | News board posts |

**Serialization:**

Objects are serialized using Ruby's `Marshal.dump` and deserialized with `Marshal.load`. The Marshal format captures the complete object graph including all instance variables except those declared as volatile.

#### Hydration Pattern

The dehydrate/rehydrate pattern manages volatile state across serialization boundaries:

**Dehydrate (pre-serialization):**
1. The Hydration module iterates all volatile instance variables declared by the class and its ancestors.
2. Volatile values are extracted into a Hash.
3. Volatile instance variables are removed from the object.
4. The stripped object is now safe for `Marshal.dump`.

**Rehydrate (post-deserialization):**
1. Called with the previously saved volatile data Hash.
2. Restores each volatile instance variable.
3. If called with `nil` (e.g., when loading from storage), initializes fresh volatile state.

Volatile declarations:
```ruby
volatile :@help_library, :@player  # In Player class
volatile :@local_registrations     # In Publisher class
```

#### Thread Safety

All GDBM file access is serialized through a single `@mutex` in StorageMachine. GDBM files are opened with `GDBM::NOLOCK` -- the mutex provides synchronization instead of GDBM's internal locking.

Read operations use `GDBM::READER + GDBM::NOLOCK`. Write operations use `GDBM::SYNC + GDBM::NOLOCK`.

### Gary (Game ARraY)

Gary is the in-memory object store. It wraps a `@ghash` Hash with Mutex protection and provides rich querying.

**Query Methods:**

| Method | Description |
| :----- | :---------- |
| `[goid]` | Direct lookup by GOID |
| `find(name, type)` | Searches by GOID first, then by generic name |
| `find_by_id(goid)` | Direct hash lookup |
| `find_by_generic(name, type)` | Scans all objects matching name against `generic`, `name`, or `alt_names` (case-insensitive). Optional type filter |
| `find_all(attrib, match)` | Finds all objects where instance variable `attrib` equals `match`. Supports type coercions: `"nil"` -> nil, `"true"` -> true, `":symbol"` -> symbol, numeric strings -> integers, class name strings -> Class constants |
| `type_count` | Returns Hash\<Class, Integer\> counting objects by type |

**Threading Model:**

- Writes (`<<`, `delete`) acquire `@mutex`.
- Reads (`[]`) acquire `@mutex`.
- Iteration (`each`) creates a snapshot (via `@ghash.each_value.dup`) and iterates without holding the mutex.

#### CacheGary

`CacheGary` extends Gary with lazy-loading from storage:

- `[goid]` -- Checks memory first; if not found but GOID exists in `@all_goids`, loads from `@storage`.
- `@all_goids` -- A Set tracking all known GOIDs, including those not currently loaded in memory.
- `unload_extra` -- Saves and removes objects with empty inventories that aren't Players, Mobiles, or busy. This reduces memory footprint for large worlds.

### Event Sourcing (Optional)

Aethyr includes an optional event sourcing system built on the Sequent framework. It is disabled by default and enabled via `ServerConfig[:event_sourcing_enabled] = true`.

#### Architecture

The event sourcing layer follows the CQRS/ES pattern:

1. **Commands** -- Intentions to change state (e.g., `CreatePlayer`, `UpdateRoomDescription`).
2. **Command Handlers** -- Validate and execute commands against aggregate roots.
3. **Aggregates** -- Domain objects that encapsulate business logic and emit events.
4. **Events** -- Immutable records of state changes, stored sequentially.
5. **Event Store** -- Persistent storage for the event stream (ImmuDB or file-based fallback).

#### Aggregate Roots

| Aggregate | Events |
| :-------- | :----- |
| `GameObject` | `GameObjectCreated`, `GameObjectAttributeUpdated`, `GameObjectContainerUpdated`, `GameObjectDeleted` |
| `Player` | `PlayerCreated`, `PlayerPasswordUpdated` |
| `Room` | `RoomCreated`, `RoomExitAdded` |

#### Dual-Write Pattern

During the transition from legacy GDBM storage to event sourcing, Aethyr uses a dual-write pattern:

- All state mutations are written to both GDBM storage and the Sequent event store.
- Operations are guarded by `ServerConfig[:event_sourcing_enabled]` and `defined?(Sequent)` checks.
- The GDBM path remains the primary source of truth; event sourcing provides an audit trail and supports future CQRS read models.

#### ImmuDB Event Store

The `ImmudbEventStore` backend stores events in ImmuDB, a tamper-evident database:

- Atomic operations with retry logic and exponential backoff.
- Snapshot support at configurable thresholds (`ServerConfig[:snapshot_threshold]`, default 100).
- Comprehensive metrics tracking (event count, aggregate count, snapshot count).

#### File-Based Fallback

If ImmuDB is unavailable, events are stored as files under `storage/events/{aggregate_id}/`:
- `.event` files for individual events.
- `.sequence` files for sequence numbers.
- `.snapshot` files for aggregate snapshots.

The fallback is transparent to the rest of the system.

#### Migration

`StorageMachine#migrate_to_event_store` migrates all existing GDBM data to the Sequent event store by loading each object and replaying its creation as events.

### Password Storage

Passwords are stored as **unsalted MD5 hashes** in the `storage/passwords` GDBM file. The `check_password` method compares the MD5 of the provided password against the stored hash.

---

## Configuration

### Server Configuration (`conf/config.yaml`)

All server settings are managed by the `ServerConfig` singleton module, which reads and writes `conf/config.yaml`.

**Complete Key Reference:**

| Key | Type | Default | Description |
| :-- | :--- | :------ | :---------- |
| `admin` | String | `"root"` | Admin player login name |
| `address` | String | `"127.0.0.1"` | Server bind address |
| `port` | Integer | `8080` | Server listen port |
| `log_level` | Integer | `2` | Logging verbosity: 0=Important, 1=Normal, 2=Medium, 3=Ultimate |
| `save_rate` | Integer | `1440` | Minutes between automatic saves (1440 = daily) |
| `update_rate` | Integer | `30` | Seconds between game object update ticks |
| `start_room` | String (GOID) | Generated | GOID of the room where new characters spawn |
| `restart_delay` | Integer | `10` | Seconds to wait before automatic restart |
| `restart_limit` | Integer | `5` | Maximum number of automatic restarts before giving up |
| `intro_file` | String | `"intro.txt"` | Path to the login banner file |
| `goid_type` | Symbol/nil | `nil` | GOID format: nil (GUID), `:hex_code`, `:integer_16`, `:integer_24`, `:integer_32` |
| `event_sourcing_enabled` | Boolean | `false` | Enable/disable the event sourcing subsystem |
| `mccp` | Boolean | `false` | Enable/disable MUD Client Compression Protocol |
| `immudb_address` | String | `"127.0.0.1"` | ImmuDB server address |
| `immudb_port` | Integer | `3322` | ImmuDB server port |
| `immudb_username` | String | `"immudb"` | ImmuDB authentication username |
| `immudb_password` | String | `"immudb"` | ImmuDB authentication password |
| `immudb_database` | String | `"aethyr"` | ImmuDB database name |
| `snapshot_threshold` | Integer | `100` | Number of events before creating an aggregate snapshot |

**Runtime Modification:**

- In-game: `aconfig <key> <value>` (admin command).
- API: `ServerConfig[key] = value` (auto-saves to YAML).
- CLI: `bin/aethyr_setup` option 6 (interactive configuration editor).

### MSSP Configuration (`conf/mssp.yaml`)

The MUD Server Status Protocol configuration defines static metadata sent to MUD listing services:

| Key | Default | Description |
| :-- | :------ | :---------- |
| `NAME` | `"Example Name"` | Server display name |
| `HOSTNAME` | `"coolmud.com"` | Server hostname |
| `STATUS` | `"ALPHA"` | Development stage |
| `GENRE` | `"Fantasy"` | Game genre |
| `SUBGENRE` | `"Medieval Fantasy"` | Game subgenre |
| `CONTACT` | `"someone@coolmud.com"` | Administrator email |
| `LANGUAGE` | `"English"` | Primary language |
| `LOCATION` | `"United States"` | Server geographic location |
| `MINIMUM AGE` | `0` | Minimum player age |
| `WEBSITE` | `"coolmud.com"` | Server website URL |
| `CLASSES` | `0` | Number of character classes |
| `LEVELS` | `0` | Number of character levels |
| `WORLDS` | `0` | Number of game worlds |

**Dynamic Values (added at runtime):**

The TelnetScanner enriches the MSSP data with live values from `$manager`:

| Key | Source |
| :-- | :----- |
| `PLAYERS` | Count of connected Player objects |
| `UPTIME` | Server start timestamp |
| `ROOMS` | Count of Room objects in Gary |
| `AREAS` | Count of Area objects in Gary |
| `OBJECTS` | Total object count in Gary |
| `CODEBASE` | `"Aethyr #{$AETHYR_VERSION}"` |
| `FAMILY` | `"Custom"` |

---

## Connection and Login

### TCP Server

The `Server` class creates a raw TCP listener socket with the following configuration:

| Setting | Value | Purpose |
| :------ | :---- | :------ |
| `SO_REUSEADDR` | `true` | Allow immediate rebind after restart |
| `TCP_NODELAY` | `true` | Disable Nagle's algorithm for interactive responsiveness |
| `SO_RCVBUF` | `262144` | 256 KB receive buffer |
| `SO_SNDBUF` | `262144` | 256 KB send buffer |
| `O_NONBLOCK` | `true` | Non-blocking socket operations |
| Backlog | `5` | Maximum pending connection queue |

**Constants:**

| Constant | Value | Description |
| :------- | :---- | :---------- |
| `RECEIVE_BUFFER_SIZE` | `4096` | Bytes per socket read |
| `SELECT_TIMEOUT` | `0.01` (10ms) | IO.select timeout for responsiveness |
| `MAX_PLAYERS` | `100` | Hard cap on simultaneous connections |

**Main Loop:**

The server runs an infinite loop that:

1. Calls `accept_nonblock` on the listener socket to accept new connections.
2. Wraps each new socket in a `PlayerConnection` via `handle_client`.
3. Calls `IO.select` with all connected sockets and `SELECT_TIMEOUT`.
4. Dispatches `player.receive_data` for each readable socket.
5. Removes errored/closed sockets.
6. Batch-cleans disconnected players.
7. Calls `$manager.pop_action` and executes the returned action.
8. Checks `global_refresh` across all displays and triggers layout recalculation if needed.

**Graceful Shutdown:**

The `ensure` block calls `$manager.stop`, `$manager.save_all`, and closes the log file. This guarantees a clean save even on crashes or signal interrupts.

### Login State Machine

The PlayerConnection's login flow is implemented as a state machine:

```
:initial -> :resolution -> :server_menu -> [:login_name | :new_name]
                                           |                |
                                    :login_password     :new_sex
                                           |                |
                                       (playing)       :new_password
                                                           |
                                                       :new_color
                                                           |
                                                       (playing)
```

#### States

**`:initial`** -- Connection established. The intro banner (`intro.txt`) is sent to the client. Transitions to `:resolution`.

**`:resolution`** -- Asks "Do you want color? (Y/n)". If yes, calls `display.init_colors` to enable 256-color rendering. Transitions to `:server_menu`.

**`:server_menu`** -- Presents three options:
1. Login -- transitions to `:login_name`
2. Create New Character -- transitions to `:new_name`
3. Quit -- disconnects

Also accepts a character name directly (skips to `:login_password` if the name exists, or `:new_name` if not).

**`:login_name`** -- Validates the name format (`/^[a-zA-Z]+$/`), checks `$manager.player_exist?`. Transitions to `:login_password`.

**`:login_password`** -- Echo disabled. Calls `$manager.load_player(name, password)`. Handles errors:
- `MUDError::UnknownCharacter` -- Name not found.
- `MUDError::BadPassword` -- Wrong password (max 3 attempts before forced disconnect).
- `MUDError::CharacterAlreadyLoaded` -- Force-disconnects the existing session.

On success: sets word_wrap, calls `player.set_connection(self)`, adds to Manager, checks admin flag against `ServerConfig.admin`, shows MOTD.

**`:new_name`** -- Validates: 3-20 characters, letters only, not already taken. Transitions to `:new_sex`.

**`:new_sex`** -- Accepts M or F. Transitions to `:new_password`.

**`:new_password`** -- Echo disabled. Validates: 6-20 word characters. Transitions to `:new_color`.

**`:new_color`** -- Accepts Y or N for color preference. Creates the character.

#### Character Creation

`create_new_player` performs the following steps:

1. Creates a `Player` object at `ServerConfig.start_room`.
2. Creates starter equipment:
   - `Shirt` (worn at `:torso`, layer 2)
   - `Pants` (worn at `:legs`, layer 2)
   - `Underwear` (worn at `:legs`, layer 3)
   - `Sword` (placed in inventory)
3. Equips clothing items via `player.wear`.
4. Calls `$manager.add_player(player, password)`.
5. Logs the creation to `logs/player.log`.

### PlayerConnection

The `PlayerConnection` wraps a TCP socket with the `Login` and `Editor` modules.

| Field | Type | Description |
| :---- | :--- | :---------- |
| `@socket` | Socket | Raw TCP socket |
| `@display` | Display | Ncurses rendering engine |
| `@in_buffer` | String | Input buffer for incomplete lines |
| `@paginator` | KPaginator | Output pagination handler |
| `@state` | Symbol | Current login state machine state |
| `@player` | Player | Assigned after successful login |
| `@expect_callback` | Proc | Next-input callback (for prompts) |
| `@editing` | Boolean | Whether the in-game editor is active |

**Input Routing:**

`receive_data` routes input through a priority chain:

1. If `@expect_callback` is set, consume it (used for confirmation prompts).
2. If `@editing`, route to the editor module.
3. If `@player` exists, route to `@player.handle_input(data)`.
4. Otherwise, route to the login state machine.

---

## Extension System

### Handler Registry

The `HandlerRegistry` is a singleton that connects command handlers to the Manager at startup.

**Registration Flow:**

1. When a command handler file is loaded (via `require`), the handler class calls `HandlerRegistry.register_handler(self)` as a class-level side effect.
2. At server startup, `HandlerRegistry.handle(manager)` iterates all registered handlers and calls `manager.subscribe(handler, on: :object_added)`.
3. When a Player object is added to the Manager (via `add_object`), the Manager broadcasts `:object_added`.
4. Each handler's `object_added` class method is called. If the object is a Player, the handler creates a new instance and subscribes it to the player's `:player_input` events.

This pattern means command handlers are automatically attached to every player without any explicit wiring code.

### Command Extensions

**Directory Layout:**

```
lib/aethyr/extensions/
  actions/
    commands/          # Command action classes
      emotes/          # Emote action subclasses
  input_handlers/      # Input handler classes (match patterns)
  objects/             # Custom game object types
  reactions/           # NPC reaction scripts (.rx)
  flags/               # Flag definitions
  skills/              # Skill definitions
  skills.rb            # Skills loader
```

**Creating a New Command:**

1. Create an input handler in `lib/aethyr/extensions/input_handlers/` or `lib/aethyr/core/input_handlers/`:

```ruby
class MyCommandHandler < Aethyr::Extend::CommandHandler
  def initialize(player)
    super(player, ["my_command"], help_entries: [...])
  end

  def player_input(data)
    if data[:input].match(/^my_command\s+(.*)$/)
      # Create and submit an action
      $manager.submit_action(MyCommandAction.new(player, target: $1))
      return true
    end
    false
  end
end
Aethyr::Extend::HandlerRegistry.register_handler(MyCommandHandler)
```

2. Create the corresponding action in `lib/aethyr/extensions/actions/commands/`:

```ruby
class MyCommandAction < Aethyr::Extend::CommandAction
  def initialize(actor, **data)
    super(actor, **data)
  end

  def action
    # Implement command logic
    @player.output("You did the thing!")
  end
end
```

The `CommandHandler` base class provides:
- `object_added(data)` -- Auto-subscribes to new Players.
- `HandleHelp` -- Registers help entries with the player's help library.

The `CommandAction` base class provides:
- `find_object(name, event)` -- Searches player inventory, room, and global objects.

### Object Extensions

Custom game objects are placed in `lib/aethyr/extensions/objects/`:

| Object | Parent | Traits | Description |
| :----- | :----- | :----- | :---------- |
| `Chair` | GameObject | Sittable | A chair that can be sat upon |
| `Shirt` | GameObject | Wearable | Clothing item (torso, layer 2) |
| `Pants` | GameObject | Wearable | Clothing item (legs, layer 2) |
| `Underwear` | GameObject | Wearable | Underclothing (legs, layer 3) |
| `Sword` | GameObject | | A basic sword weapon |
| `Dagger` | GameObject | | A dagger weapon |
| `Key` | GameObject | | A key for unlocking doors |
| `Lever` | GameObject | | An interactive lever |
| `Newsboard` | Container | News | A bulletin board for posts |
| `Parchment` | GameObject | Readable | A readable parchment |

### Skill Extensions

Skills inherit from `Aethyr::Skills::Skill` and are registered via the skills loader:

```ruby
# lib/aethyr/extensions/skills/kick.rb
class Aethyr::Extensions::Skills::Kick < Aethyr::Skills::Skill
  def initialize(owner)
    super(owner, :kick, "Kick", "Kick your opponent where it hurts.", :skill)
  end
end
```

### Flag Extensions

Flags inherit from `Flag` and define opposing relationships:

```ruby
class PlusFire < Flag
  def initialize(affected)
    super(affected, :plus_fire, "+fire",
          "<firehigh>so hot it is hard to breathe</firehigh>",
          "The area is fiery and hot.",
          [:minus_fire])  # Negates MinusFire
  end
end
```

### Reaction Script Extensions

New reaction scripts are `.rx` files placed in `lib/aethyr/extensions/reactions/`. They are loaded onto Mobile objects via:

```ruby
mobile.load_reactions("helper")  # Loads helper.rx
```

Reaction scripts can be reloaded at runtime via `mobile.reload_reactions`.

---

## World Generation

### ESA WorldCover Integration

Aethyr generates real-world-mirroring game geography using ESA WorldCover 10m satellite land-cover data. The data is GeoTIFF raster imagery hosted on an AWS S3 bucket, processed via the GDAL library.

**Data Source:** ESA WorldCover 10m v200, covering global land cover classification at 10-meter resolution.

**Resolution:** Each game room represents a configurable area (default: `RESOLUTION_METRES = 5000`, i.e., 5km per room edge).

### Pipeline Architecture

The `WorldCoverGenerator` uses a 5-stage concurrent pipeline:

| Stage | Thread Count | Input | Output | Description |
| :---- | :----------- | :---- | :----- | :---------- |
| 1. Download | `MAX_CONCURRENT_DL` (10) | Tile coordinates | GeoTIFF files | Downloads tiles from S3, caches locally in `worldcover/` |
| 2. Process | `MAX_CONCURRENT_PROC` (CPU×4, min 4) | GeoTIFF files | ProcessedRoom structs | Reads raster via GDAL, maps pixels to terrain types |
| 3. Create | 1 | ProcessedRoom structs | Room objects | Creates Aethyr Room objects with terrain-appropriate names/descriptions |
| 4. Connect | 1 | RoomConnection structs | Exit objects | Links adjacent rooms with directional exits |
| 5. Monitor | 1 | Counters | Log output | Reports progress statistics |

**Inter-thread Communication:**

All stages communicate via Ruby `Queue` objects (thread-safe):
- `@download_queue` -- Download stage input
- `@process_queue` -- Processing stage input
- `@processed_rooms` -- Creation stage input
- `@room_connections` -- Connection stage input

**Concurrency Controls:**
- `@mutex` protects shared counters (`@downloaded`, `@processed`).
- `@room_lookup_mutex` protects the position-to-GOID mapping hash.
- Thread-local batching reduces lock contention during room creation.

### Terrain Mapping

The WorldCover land-cover classification codes are mapped to Aethyr terrain types:

| WorldCover Code | Land Cover Class | Aethyr Terrain |
| :-------------- | :--------------- | :------------- |
| 10 | Tree cover | `GRASSLAND` |
| 20 | Shrubland | `GRASSLAND` |
| 30 | Grassland | `GRASSLAND` |
| 40 | Cropland | `GRASSLAND` |
| 50 | Built-up | `CITY` |
| 60 | Bare / sparse vegetation | `TUNDRA` |
| 70 | Snow and ice | `TUNDRA` |
| 80 | Permanent water bodies | (water room) |
| 90 | Herbaceous wetland | `GRASSLAND` |
| 95 | Mangroves | `GRASSLAND` |
| 100 | Moss and lichen | `TUNDRA` |

Each terrain type generates rooms with procedural names and descriptions appropriate to the biome.

---

## Architecture

### System Overview

Aethyr follows a **three-layer architecture** with strict dependency inversion:

| Layer | Components | Responsibility |
| :---- | :--------- | :------------- |
| **Infrastructure** | Server, Socket, GDBM, Config, Logger, GDAL | Network I/O, persistence, configuration, logging |
| **Domain** | Manager, Gary, EventHandler, Calendar, GameObjects, Traits | Game world simulation, object lifecycle, event processing |
| **Interface** | InputHandlers, CommandActions, Display, Format, Editor | Player input parsing, command execution, terminal rendering |

Each layer depends only on the layer beneath it. The Interface layer depends on Domain; Domain depends on Infrastructure. Infrastructure has no upward dependencies.

### Threading Model

Aethyr runs on 3 primary threads with additional threads for world generation:

| Thread | Purpose | Cycle |
| :----- | :------ | :---- |
| **Main Thread** | TCP select loop, action dispatch, display refresh | Continuous (10ms select timeout) |
| **Update TimerTask** | Calls `$manager.update_all` (game tick: object updates, calendar tick) | Every `update_rate` seconds (default 30) |
| **Save TimerTask** | Calls `$manager.save_all` (persistence) | Every `save_rate` seconds (default 86400) |

**Synchronization Points:**

| Resource | Protection | Pattern |
| :------- | :--------- | :------ |
| GDBM files | `StorageMachine#@mutex` | Serialized access (single mutex for all files) |
| Gary writes | `Gary#@mutex` | Mutex-protected insertion/deletion |
| Gary iteration | Snapshot (`dup`) | Iterates a copy without holding the mutex |
| Manager state | `EventHandler#@mutex` | `try_lock` ensures single-threaded event processing |

### Design Patterns

| Pattern | Implementation | Location |
| :------ | :------------- | :------- |
| **Observer / Pub-Sub** | Wisper gem | Publisher, Manager, Player, CommandHandler |
| **Command** | Actions as executable objects with `action` method | Action, CommandAction, Event |
| **Strategy** | Pluggable input handlers, terrain types, persistence backends | CommandHandler, Display layout, StorageMachine |
| **Facade** | Manager wraps Storage, EventHandler, Gary, Calendar | Manager |
| **Factory** | `Manager.create_object(klass, ...)` for all game objects | Manager |
| **Template Method** | `run` and `alert` hooks in GameObject; Rake task builders | GameObject, LivingObject, Mobile |
| **Null Object** | `method_missing` returns nil instead of raising | GameObject |
| **State Machine** | Login flow states; Display `@read_stage` | Login module, Display |
| **Decorator / Mixin** | Traits composed onto objects at class definition | Reacts, Respawns, HasInventory, Openable, Position, etc. |
| **Repository** | Gary as in-memory object store, StorageMachine for persistence | Gary, CacheGary, StorageMachine |
| **Builder** | Rake task builders for test configuration | Rakefile |
| **Service Locator** | HandlerRegistry as global handler discovery | HandlerRegistry |
| **Chain of Responsibility** | Event attachment for sequential execution | Event#attach_event |
| **Composite** | FormatState parent-chain inheritance | FormatState |
| **Fibonacci Heap** | PriorityQueue for action scheduling | PriorityQueue |

### Data Flow

#### Input Pipeline

```
TCP Socket
  -> IO.select (Server main loop)
    -> PlayerConnection#receive_data
      -> Login state machine (if not logged in)
      -> Player#handle_input (broadcasts :player_input via Wisper)
        -> CommandHandler#player_input (regex matching)
          -> CommandAction created
            -> $manager.submit_action (pushes to PriorityQueue)
              -> Server main loop: $manager.pop_action
                -> action.action (executes the command)
```

#### Output Pipeline

```
CommandAction#action
  -> Player#output(message)
    -> PlayerConnection#say(message)
      -> Display#send(message, message_type:)
        -> Window routing (main, chat, look, etc.)
          -> FormatState#apply (color/formatting)
            -> Ncurses window write
              -> TCP Socket
```

#### Persistence Flow

```
Save: Manager#save_all
  -> StorageMachine#save_all
    -> For each object:
      -> object.dehydrate() (strip volatile state)
        -> Marshal.dump (serialize)
          -> GDBM write (to storage/<ClassName>)
        -> object.rehydrate() (restore volatile state)

Load: StorageMachine#load_all
  -> For each GOID in storage/goids:
    -> GDBM read (from storage/<ClassName>)
      -> Marshal.load (deserialize)
        -> Reconstruct inventories and equipment
          -> object.rehydrate(nil) (initialize fresh volatile state)
            -> Gary << object
```

### Docker Deployment

**Dockerfile:**

The production Dockerfile uses Arch Linux as the base image:

1. Installs system dependencies: ruby, git, gdal, nodejs, npm, postgresql-libs, glibc
2. Installs Bundler ~> 2.6
3. Copies the application and runs `bundle install`
4. Exposes port 8888
5. CMD: `bundle exec ./bin/aethyr run`

**docker-compose.yml:**

```yaml
services:
  aethyr:
    image: borea/aethyr:latest
    build: .
    ports:
      - "1337:8888"
    volumes:
      - .:/usr/src/app
```

- Host port `1337` maps to container port `8888`.
- The local workspace is bind-mounted for live development.

### Dependencies

#### Runtime Gems

| Gem | Version | Purpose |
| :-- | :------ | :------ |
| `wisper` | ~> 2.0 | In-process pub/sub event bus |
| `methadone` | ~> 2.0 | CLI framework with option parsing |
| `eventmachine` | ~> 1.2 | Event-driven I/O (legacy, partially removed) |
| `require_all` | ~> 2.0 | Recursive file requiring |
| `concurrent-ruby` | ~> 1.3 | Thread-safe data structures, TimerTask |
| `ncursesw` | ~> 1.4 | Ncurses bindings for terminal rendering |
| `gdbm` | ~> 2.1 | GNU Database Manager for persistence |
| `base64` | ~> 0.2 | Base64 encoding utilities |
| `logger` | ~> 1.5 | Logging framework |
| `immudb` | ~> 0.3 | ImmuDB client for event sourcing |
| `sequent` | ~> 8.2 | CQRS/Event Sourcing framework |
| `gdal` | ~> 3.0 | Geospatial raster processing for world generation |

#### Development Gems

| Gem | Purpose |
| :-- | :------ |
| `bundler` | Dependency management |
| `rake` | Task runner |
| `rdoc` | Documentation generation |
| `rubocop` | Code style linting |
| `test-unit` | Unit testing framework |
| `simplecov` + `simplecov-console` | Code coverage (85% minimum for unit, 35% for integration) |
| `cucumber` ~> 9.2 | BDD testing framework |
| `rspec` + `rspec-mocks` | Specification testing |
| `ruby-prof` | Performance profiling |
| `aruba` | CLI testing |

### Testing

Aethyr uses a BDD-first testing approach with Cucumber/Gherkin as the primary framework.

**Test Structure:**

| Directory | Type | Count | Description |
| :-------- | :--- | :---- | :---------- |
| `tests/unit/` | Unit | 200+ `.feature` files | Tests for every command, handler, object, and trait |
| `tests/integration/` | Integration | 4 `.feature` files | Full server boot, character creation, CLI, layout testing |
| `tests/unit/step_definitions/` | Steps | 170+ step files | Step implementations for unit features |
| `tests/integration/step_definitions/` | Steps | Integration step implementations | Server harness steps |

**Rake Tasks:**

| Task | Description |
| :--- | :---------- |
| `rake unit` (default) | Run unit tests with coverage |
| `rake unit_nocov` | Run unit tests without coverage |
| `rake integration` | Run integration tests with coverage |
| `rake integration_nocov` | Run integration tests without coverage |
| `rake unit_profile` | Run unit tests with ruby-prof profiling |
| `rake integration_profile` | Run integration tests with profiling |
| `rake rdoc` | Generate YARD documentation |
| `rake documentation` | Build Docusaurus documentation site |
| `rake documentation_serve` | Serve Docusaurus site locally |

**Coverage Thresholds:**

| Suite | Minimum |
| :---- | :------ |
| Unit | 85% |
| Integration | 35% |

### Logging

The custom `Logger` class provides 4 verbosity levels:

| Level | Constant | Description |
| :---- | :------- | :---------- |
| 0 | `Logger::Important` | Critical messages only |
| 1 | `Logger::Normal` | Standard operational messages |
| 2 | `Logger::Medium` | Detailed operational messages (default) |
| 3 | `Logger::Ultimate` | Maximum verbosity (includes password comparisons) |

Log output goes to `logs/server.log` and the console. The log level is configurable via `ServerConfig[:log_level]`, the `--verbose` CLI flag, and the `USR1` signal for runtime toggling.

### Error Handling

Custom exception classes defined in `MUDError`:

| Exception | Raised When |
| :-------- | :---------- |
| `UnknownCharacter` | Login attempt with unknown character name |
| `BadPassword` | Login attempt with incorrect password |
| `CharacterAlreadyLoaded` | Attempting to load a character that is already in the game |
| `NoSuchGOID` | GOID not found in storage registry |
| `ObjectLoadError` | Object loads as nil from storage |
| `Shutdown` | Server shutdown initiated from within the game |

The EventHandler catches `NameError` (unknown event type module) and general `Exception` (handler crashes) during event dispatch, logging errors without crashing the server.

---

## In-Game Editor

Players can compose multi-line text using the built-in editor, activated by commands like `write_post` or `write`.

### Editor Commands

| Command | Description |
| :------ | :---------- |
| `*help [command]` | Display editor help |
| `*save` | Save the buffer and exit the editor |
| `*quit` | Discard changes and exit (prompts for confirmation) |
| `*clear` | Clear the entire buffer |
| `*echo` | Display the full buffer with line numbers |
| `*more` | Display the remaining buffer content |
| `*line <n>` | Move the cursor to line n |
| `*delete <n>` | Delete line n |
| `*replace <n> <text>` | Replace line n with new text |

During editing, the player is temporarily removed from the game world (moved to "limbo"). On save or quit, the player is returned to their previous room via `info.former_room`.

---

## Documentation

Aethyr ships with a Docusaurus-based documentation site.

### Documentation Structure

| Path | Title | Content |
| :--- | :---- | :------ |
| `docs/index.md` | Home | Landing page with navigation links |
| `docs/overview.md` | Overview | High-level project description, Kroki diagram demo |
| `docs/server/running-server.md` | Running the Server | Prerequisites, Docker/native setup, lifecycle commands |
| `docs/server/administration.md` | Administration | Permission model, moderation, world inspection, process control |
| `docs/server/world-building.md` | World Building | Room/exit/object creation, persistence, terrain |
| `docs/server/event-sourcing.md` | Event Sourcing | Architecture, commands, events, aggregates, ImmuDB, migration |
| `docs/developer/architecture.md` | Architecture | Layer cake, key classes, extension points, DI, testing |
| `docs/developer/extending.md` | Extending | Tutorial: skills, commands, emotes, packaging |
| `docs/player/commands.md` | Commands | Complete player command reference |
| `docs/player/lore.md` | Lore | Placeholder for server-specific story content |
| `docs/event_sourcing_documentation.md` | Event Sourcing (detailed) | Extended ES documentation |

### Custom Plugins

The documentation build uses a custom Remark plugin (`docs/plugins/remark-kroki-inline.js`) that converts Kroki fenced code blocks (e.g., `kroki-plantuml`) into inline SVG data URIs during the build phase. This eliminates external requests at documentation runtime.
