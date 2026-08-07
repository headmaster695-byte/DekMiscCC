# Quote Board

HOI4-style rotating tips and quotes on an Advanced Monitor, with multi-speaker music and optional Chat Box capture.

Requires **CC: Tweaked 1.119.x** (Minecraft 1.21.1 NeoForge).

## Files

All three must sit in the **same directory** on the computer:

| File | Role |
|------|------|
| `quote-board.lua` | Main program — config, display, chat, music loop |
| `songs.lua` | Song library (`require("songs")`) |
| `quotes.lua` | Built-in quote pool (`require("quotes")`) |

## Hardware

| Peripheral | Required? | Notes |
|------------|-----------|-------|
| Advanced Monitor (colour) | **Yes** | Display surface (touch advances quotes) |
| Speaker(s) | Optional | Multiple speakers = polyphonic voices |
| Chat Box ([Advanced Peripherals](https://modrinth.com/mod/advanced-peripherals)) | Optional | Captures player chat as quotes |

Missing speakers or Chat Box logs a warning; the board still runs.

## Install

```
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/quote-board.lua quote-board.lua
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/songs.lua songs.lua
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/quotes.lua quotes.lua
```

Or copy the whole `scripts/quote-board/` folder onto the computer.

## Run

```
quote-board
```

Auto-start from `startup.lua`:

```lua
shell.run("quote-board")
```

## Controls

| Input | Action |
|-------|--------|
| `R` | Next quote |
| `N` | Skip current song |
| `M` | Mute / unmute music |
| `Q` or `Ctrl+T` | Quit |
| Monitor touch | Next quote |

## Behaviour

### Quotes

Cycles every 15 seconds (see `QUOTE_INTERVAL`). A live **next Ns** countdown sits on the category row.

Selection is weighted so the next quote prefers a **different category**. Player-captured quotes get a slightly higher weight.

| Badge | Colour | Style |
|-------|--------|-------|
| `[ TIP ]` | Yellow | Dry gameplay advice |
| `[ DID YOU KNOW ]` | Cyan | Odd facts |
| `[ WISDOM ]` | Lime | Motivational, undercut by reality |
| `[ LOADING ]` | Light grey | Loading-screen asides |
| `[ QUOTE ]` | Orange | Real-life misquotations |
| `[ PLAYER ]` | Pink | Captured from player chat |

### Chat capture

When a Chat Box is attached:

- Player messages become `[ PLAYER ]` quotes and persist in `quote-board-chat.dat`
- Fresh captures **jump onto the board immediately** with a short `LIVE: <name>` header flash
- Exact duplicate messages (recent) are ignored
- Commands starting with `/` or `!`, and short messages under `MIN_MSG_LEN`, are ignored

Detection tries `chatBox`, `chat_box`, `chatbox`, then any peripheral type containing `"chat"`. Events: `chat` and `chat_message`.

If auto-detect fails, set `CHAT_BOX_NAME` to the side/name from the startup peripheral dump.

### Music

- **A New Start (Lofi Remix)** always plays first after boot
- After that, songs are chosen at random (no immediate repeat)
- Mute (`M`) and skip (`N`) interrupt the current track cleanly
- Voice count depends on the song and how many speakers are attached:
  - Title track: up to 3 voices
  - Elevator tracks: up to 2 voices
  - Zelda-inspired tracks: up to 4 voices
  - Originals (Ancient Temple, Kokiri Home): up to 6 voices
- If a song errors, the loop continues with the next track
- Footer shows the track name, or `MUTED` in red

## Config

Edit the constants at the top of `quote-board.lua`:

| Constant | Default | Meaning |
|----------|---------|---------|
| `QUOTE_INTERVAL` | `15` | Seconds between quote changes |
| `MONITOR_SCALE` | `0.5` | Monitor text scale |
| `CHAT_FILE` | `quote-board-chat.dat` | Persisted chat quotes |
| `MAX_CHAT_QUOTES` | `50` | Cap on stored chat quotes |
| `MIN_MSG_LEN` | `10` | Minimum chat length to capture |
| `CHAT_BOX_NAME` | `""` | Blank = auto-detect |
| `DIFF_CAT_WEIGHT` | `4` | Weight for a different category |
| `SAME_CAT_WEIGHT` | `1` | Weight for the same category |
| `PLAYER_CAT_WEIGHT` | `6` | Weight for PLAYER quotes |
| `TITLE_SONG_IDX` | `1` | Song index that always plays first |
| `MUSIC_START_ON` | `true` | Start unmuted |
| `FRESH_CHAT_FOCUS` | `true` | Jump to new chat quotes |
| `TOUCH_ADVANCES` | `true` | Monitor tap advances quote |

## Layout

```
+----------------------------------+
|     * MOTIVATIONAL CORNER *      |   (or LIVE: PlayerName)
+----------------------------------+
| [ TIP ]                  next 12s|
|                                  |
|   "The quote text goes here"     |
|                                  |
|                    — Attribution |
+----------------------------------+
|  * Song Name | 4spk | chat:3     |
+----------------------------------+
```
