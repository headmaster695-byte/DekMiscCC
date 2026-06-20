# quote-board

A rotating display of semi-motivational, semi-incorrect tips and quotes in the style of HOI4 loading screens — paired with continuous elevator music and live chat capture that automatically feeds player messages into the quote rotation.

## Requirements

| Peripheral | Required? | Purpose |
|------------|-----------|---------|
| Advanced Monitor | **Yes** | The display surface (must be colour/advanced) |
| Speaker | Optional | Elevator-music playback |
| Chat Box | Optional | Captures player chat as live quotes (requires [Advanced Peripherals](https://modrinth.com/mod/advanced-peripherals)) |

The script starts in degraded mode if the Speaker or Chat Box is absent — it logs a warning, then continues with whatever is available.

## Installation

```
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/quote-board.lua quote-board.lua
```

## Usage

```
quote-board
```

The script runs indefinitely. Press `Ctrl+T` to stop it — the terminal and monitor are always cleaned up on exit.

To run it automatically when the computer starts, add this line to `startup.lua`:

```lua
shell.run("quote-board")
```

## What It Does

### Quote Display

The Advanced Monitor cycles through quotes every 15 seconds (configurable). Each quote shows:

- A coloured category badge
- The quote body (word-wrapped)
- A right-aligned attribution
- A music info bar at the bottom

**Built-in categories:**

| Badge | Colour | Style |
|-------|--------|-------|
| `[ TIP ]` | Yellow | Subtly wrong gameplay advice |
| `[ DID YOU KNOW ]` | Cyan | Comedically incorrect facts |
| `[ WISDOM ]` | Lime | Motivational but undercut by reality |
| `[ LOADING ]` | Light grey | Meta/loading-screen humour |
| `[ QUOTE ]` | Orange | Real-life misquotations and famous lines taken slightly out of context |
| `[ PLAYER ]` | Pink | Captured verbatim from player chat |

### Elevator Music

The Speaker plays five looping instrumental phrases:

| Track | Instrument | Mood |
|-------|-----------|------|
| Bossa Waiting | Harp | Smooth, chill |
| Corporate Zen | Flute | Ascending / descending scale |
| Executive Chime | Chime | Gentle waltz-like arpeggio |
| Lobby Bell | Bell | Descending melodic phrase |
| Penthouse Suite | Harp + Bell | Layered texture |

Songs cycle continuously without gaps. The currently playing track name is shown in the monitor's bottom bar.

### Chat Capture

When a Chat Box peripheral is attached, the script automatically captures player messages and adds them to the quote rotation under the `[ PLAYER ]` category.

**Detection** — the script tries several peripheral type strings that Advanced Peripherals has used across versions (`chatBox`, `chat_box`, `chatbox`) and also falls back to scanning all attached peripherals for any type name containing "chat". On startup, every attached peripheral is printed to the terminal so you can see exactly what was found.

**Events** — the script listens for both `"chat"` and `"chat_message"` event names (Advanced Peripherals has shipped both). You do not need to know which one your version uses.

**Manual override** — if auto-detection still fails, set `CHAT_BOX_NAME` in the config section to the exact peripheral side or name shown in the startup diagnostics (e.g. `"left"`, `"peripheral_0"`).

**Message filter:**
- Minimum length: 10 characters (configurable via `MIN_MSG_LEN`)
- Ignored: messages starting with `/` (commands) or `!` (bot prefixes)

Captured quotes are stored persistently in `quote-board-chat.dat` so they survive reboots. Up to 50 are kept; the oldest is dropped when the limit is reached.

## Monitor Setup

Place **Advanced Monitor** blocks adjacent to (or in a chain connected to) the computer. A 3-wide × 2-tall array gives a good amount of readable space. The default text scale is `0.5`, which packs in more text per block.

To send output to a specific monitor side (e.g. if `peripheral.find` picks the wrong one), wrap the call in `startup.lua`:

```lua
local mon = peripheral.wrap("monitor_0")  -- replace with your monitor name
term.redirect(mon)
shell.run("quote-board")
term.restore()
```

## Configuration

Open `quote-board.lua` in the editor (`edit quote-board.lua`) and change the values in the **Configuration** block near the top:

| Variable | Default | Description |
|----------|---------|-------------|
| `QUOTE_INTERVAL` | `15` | Seconds each quote is shown |
| `MONITOR_SCALE` | `0.5` | Text scale sent to the monitor |
| `CHAT_FILE` | `"quote-board-chat.dat"` | File where chat quotes are saved |
| `MAX_CHAT_QUOTES` | `50` | Maximum chat quotes to keep |
| `MIN_MSG_LEN` | `10` | Minimum chat message length to capture |
| `CHAT_BOX_NAME` | `""` | Force a specific peripheral side/name for the Chat Box (blank = auto) |

## Adding More Built-in Quotes

Add entries to the `BUILTIN_QUOTES` table inside `quote-board.lua`. Each entry is a three-element array:

```lua
{ "Your quote text here.", "Attribution", "CATEGORY" },
```

Valid categories: `"TIP"`, `"DID YOU KNOW"`, `"WISDOM"`, `"LOADING"`, `"QUOTE"` (or any new string — just add a colour for it in `CATEGORY_COLOUR`).

The `"QUOTE"` category is intended for real-life quotes, famous misquotations, and lines taken slightly out of context. Attribution format is `"Person/Source — brief clarification"`, e.g.:

```lua
{ "Elementary, my dear Watson.", "Sherlock Holmes — never written by Doyle", "QUOTE" },
```

## Adding More Music

Add a song to the `SONGS` table. Each note is `{ instrument, volume, pitch, sleep_after_seconds }`:

```lua
{
  name  = "My New Track",
  notes = {
    { "harp", 1.0, 6,  0.4 },   -- C4
    { "harp", 1.0, 10, 0.4 },   -- E4
    { "harp", 1.0, 13, 0.8 },   -- G4 (longer)
    -- ...
  },
},
```

Pitch reference: `C4=6  D4=8  E4=10  F4=11  G4=13  A4=15  B4=17  C5=18`  
Valid instruments: `"harp"` `"flute"` `"bell"` `"chime"` `"xylophone"` `"guitar"` `"bass"` `"banjo"` `"pling"` and others listed in the CC:T docs.
