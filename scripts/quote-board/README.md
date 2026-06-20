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

When a Chat Box peripheral is attached, the script listens for the `chat` event (fired by Advanced Peripherals whenever a player sends a message). Messages that pass the filter are saved and added to the quote rotation immediately:

- Minimum length: 10 characters (configurable)
- Ignored: messages starting with `/` (commands) or `!` (bot prefixes)
- Attributed to the player's username under the `[ PLAYER ]` category

Captured quotes are stored persistently in `quote-board-chat.dat` (a serialised Lua table) so they survive reboots. Up to 50 chat quotes are kept; the oldest is dropped when the limit is reached.

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

## Adding More Built-in Quotes

Add entries to the `BUILTIN_QUOTES` table inside `quote-board.lua`. Each entry is a three-element array:

```lua
{ "Your quote text here.", "Attribution", "CATEGORY" },
```

Valid categories: `"TIP"`, `"DID YOU KNOW"`, `"WISDOM"`, `"LOADING"` (or any new string — just add a colour for it in `CATEGORY_COLOUR`).

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
