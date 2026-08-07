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
| Advanced Monitor (colour) | **Yes** | Display surface |
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

Stop with `Ctrl+T`. Speakers and the terminal are cleaned up on exit.

Auto-start from `startup.lua`:

```lua
shell.run("quote-board")
```

## Behaviour

### Quotes

Cycles every 15 seconds (see `QUOTE_INTERVAL`). Selection is weighted so the next quote prefers a **different category** from the current one.

| Badge | Colour | Style |
|-------|--------|-------|
| `[ TIP ]` | Yellow | Subtly wrong gameplay advice |
| `[ DID YOU KNOW ]` | Cyan | Comedically incorrect facts |
| `[ WISDOM ]` | Lime | Motivational, undercut by reality |
| `[ LOADING ]` | Light grey | Meta / loading-screen humour |
| `[ QUOTE ]` | Orange | Real-life misquotations and famous lines slightly out of context |
| `[ PLAYER ]` | Pink | Captured from player chat |

Chat quotes persist in `quote-board-chat.dat` (capped by `MAX_CHAT_QUOTES`).

### Music

- **A New Start (Lofi Remix)** always plays first after boot
- After that, songs are chosen at random (no immediate repeat)
- Voice count depends on the song and how many speakers are attached:
  - Title track: up to 3 voices
  - Elevator tracks: up to 2 voices
  - Zelda-inspired tracks: up to 4 voices
  - Originals (Ancient Temple, Kokiri Home): up to 6 voices
- If a song errors, the loop continues with the next track
- The current track name appears in the monitor footer

### Chat capture

Detection tries `chatBox`, `chat_box`, `chatbox`, then any peripheral type containing `"chat"`. Events listened for: `chat` and `chat_message`.

If auto-detect fails, set `CHAT_BOX_NAME` in the config to the exact side/name from the startup peripheral dump (e.g. `"left"`).

Messages shorter than `MIN_MSG_LEN`, or starting with `/` or `!`, are ignored.

## Config

Edit the constants at the top of `quote-board.lua`:

| Constant | Default | Meaning |
|----------|---------|---------|
| `QUOTE_INTERVAL` | `15` | Seconds between quote changes |
| `MONITOR_SCALE` | `0.5` | Monitor text scale |
| `CHAT_FILE` | `quote-board-chat.dat` | Persisted chat quotes |
| `MAX_CHAT_QUOTES` | `50` | Cap on stored chat quotes |
| `MIN_MSG_LEN` | `10` | Minimum chat length to capture |
| `CHAT_BOX_NAME` | `""` | Blank = auto-detect; else peripheral name |
| `DIFF_CAT_WEIGHT` | `4` | Weight for a different category |
| `SAME_CAT_WEIGHT` | `1` | Weight for the same category |
| `TITLE_SONG_IDX` | `1` | Song index that always plays first |

## Layout

```
+----------------------------------+
|     * MOTIVATIONAL CORNER *      |
+----------------------------------+
| [ TIP ]                          |
|                                  |
|   "The quote text goes here"     |
|                                  |
|                    — Attribution |
+----------------------------------+
|  * Song Name | N spk | chat: K   |
+----------------------------------+
```
