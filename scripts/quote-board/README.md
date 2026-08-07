# Quote Board

HOI4-style rotating tips and quotes on Advanced Monitors, with multi-speaker music, live chat capture, and remote chat commands.

Requires **CC: Tweaked 1.119.x** (Minecraft 1.21.1 NeoForge).

## Files

All three must sit in the **same directory** on the computer:

| File | Role |
|------|------|
| `quote-board.lua` | Main program |
| `songs.lua` | Song library |
| `quotes.lua` | Built-in quote pool |

## Hardware

| Peripheral | Required? | Notes |
|------------|-----------|-------|
| Advanced Monitor (colour) | **Yes** | Touch advances quotes; multiple monitors are mirrored |
| Speaker(s) | Optional | Multiple speakers = polyphonic voices |
| Chat Box ([Advanced Peripherals](https://modrinth.com/mod/advanced-peripherals)) | Optional | Captures chat + accepts `#` commands |

## Install

```
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/quote-board.lua quote-board.lua
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/songs.lua songs.lua
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/quotes.lua quotes.lua
```

## Controls

| Input | Action |
|-------|--------|
| `R` | Next quote |
| `P` | Previous quote |
| `Space` | Pause / resume quote rotation |
| `N` | Skip song |
| `M` | Mute / unmute |
| `-` / `=` | Volume down / up |
| `C` | Cycle category filter |
| `L` | Cycle music playlist |
| `H` | Help overlay + session stats |
| `Q` / `Ctrl+T` | Quit |
| Monitor touch | Next quote (or dismiss help) |

## Chat commands

Prefix `#` (configurable). Anyone can use these when a Chat Box is present:

| Command | Action |
|---------|--------|
| `#next` | Next quote |
| `#prev` | Previous quote |
| `#pause` | Pause / resume |
| `#skip` | Skip song |
| `#mute` | Mute / unmute |
| `#vol 50` | Set volume 0–100 |
| `#cat` | Cycle category filter |
| `#playlist` | Cycle playlist |
| `#help` | Help overlay |
| `#stats` | Flash uptime / counts |

Normal chat (not a command, long enough, not `/` or `!`) is captured as a `[ PLAYER ]` quote.

## Features

### Quotes
- Weighted rotation prefers a **different category** each time
- Player quotes weighted higher
- Category filter lock (`C` / `#cat`): ALL → TIP → DID YOU KNOW → …
- Pause freezes the timer; progress bar shows time-to-next
- Previous-quote history
- Long quotes auto-scroll
- Soft click on quote change (optional)

### Chat
- Fresh captures jump onto the board with a `LIVE: name` flash
- Recent duplicate messages ignored
- Optional ignore-list for bots / players
- Persisted in `quote-board-chat.dat`

### Music
- **A New Start** always plays first after boot
- Shuffle bag (no repeats until the bag empties)
- Playlists: All / Elevator / Zelda-inspired / Originals / Title only
- Volume control + mute; settings persist in `quote-board-settings.dat`
- Interruptible timeline playback (skip/mute/chat never get swallowed)

### Display
- Boot splash
- Clock in the header
- Mirrored across all attached colour monitors
- Help overlay with session stats (uptime, quotes shown, chat captured)

## Config

Top of `quote-board.lua`:

| Constant | Default | Meaning |
|----------|---------|---------|
| `BOARD_TITLE` | `MOTIVATIONAL CORNER` | Header title |
| `QUOTE_INTERVAL` | `15` | Seconds between quotes |
| `MONITOR_SCALE` | `0.5` | Text scale |
| `CHAT_CMD_PREFIX` | `#` | Chat command prefix |
| `MIRROR_ALL_MONITORS` | `true` | Draw on every colour monitor |
| `SHOW_CLOCK` | `true` | Header clock |
| `SHOW_PROGRESS_BAR` | `true` | Timer bar above footer |
| `AUTO_SCROLL` | `true` | Scroll tall quotes |
| `DEFAULT_VOLUME` | `1.0` | Initial volume (overridden by saved settings) |
| `FRESH_CHAT_FOCUS` | `true` | Jump to new chat quotes |
| `QUOTE_TICK_SOUND` | `true` | Click on quote change |
| `IGNORE_PLAYERS` | `{}` | Names that are never captured |
| `PLAYER_CAT_WEIGHT` | `6` | Weight for PLAYER quotes |
| `TITLE_SONG_IDX` | `1` | First song after boot |

## Persisted files

| File | Contents |
|------|----------|
| `quote-board-chat.dat` | Captured player quotes |
| `quote-board-settings.dat` | Volume, mute, playlist, category filter |

## Layout

```
+------------------------------------------+
|  * MOTIVATIONAL CORNER *           14:32 |
+------------------------------------------+
| [ TIP ]                        next 12s  |
|                                          |
|   "The quote text goes here"             |
|                            — Attribution |
| ==================---------------------- |
|  * Song Name | 4spk | Elevator | 80%     |
+------------------------------------------+
```
