# Quote Board

HOI4-style rotating tips and quotes on Advanced Monitors, with multi-speaker music, live chat capture, and remote chat commands.

Requires **CC: Tweaked 1.119.x** (Minecraft 1.21.1 NeoForge).

## Files

All four must sit in the **same directory** on the computer:

| File | Role |
|------|------|
| `quote-board.lua` | Main program |
| `apps.lua` | Mini-app launcher (jukebox, library, …) |
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
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/quote-board/apps.lua apps.lua
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
| `S` | Cycle atmosphere scene |
| `A` | Open / close apps |
| `X` | Back to launcher / board |
| `H` | Help overlay + session stats |
| `Q` / `Ctrl+T` | Quit |
| Monitor touch | Toolbar buttons (Mute/Skip/Apps/…) or tap quote body for next |

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
| `#scene dusk` | Activate an atmosphere (also `auto` / `list` / `clear`) |
| `#help` | Help overlay |
| `#stats` | Flash uptime / counts |
| `#apps` | Open app launcher |
| `#app jukebox` | Open a named app |
| `#home` | Return to the quote board |

Normal chat (not a command, long enough, not `/` or `!`) is captured as a `[ PLAYER ]` quote.

## Apps

Press `A` (or `#apps`) for the launcher. Quote rotation pauses while an app is open; music keeps playing.

| App | What it does |
|-----|----------------|
| **Jukebox** | Browse all tracks, Enter/tap to queue one now |
| **Quote Library** | Flip through the pool; Enter pins one to the board |
| **Quote Workshop** | Create, rewrite, and enable custom quotes (all start **off**) |
| **Atmospheres** | Scene presets: playlist + quote filter + title (optional daypart auto) |
| **Chat Log** | Newest player quotes; Enter pins to the board |
| **Clock** | Large live clock + uptime |
| **Stats** | Session counts, categories, playlist sizes |
| **Dice** | Roll d2–d100 for the room |
| **About** | Short board blurb |

### Quote Workshop

Custom quotes live in `quote-board-custom.dat` and **do not appear in the rotation until enabled**.

| Key | Action |
|-----|--------|
| `N` | New quote (starts OFF) |
| `B` | Copy a builtin to rewrite (starts OFF) |
| `R` / Enter | Rewrite selected custom |
| `E` | Toggle enabled in the pool |
| `D` | Delete |
| In editor | Type text/source; Tab fields; on Category use ←/→ and `T` for on/off; Enter save; X cancel |

`X` returns to the launcher (or the board from the launcher). `A` always jumps back to the board.

### Atmospheres (scenes)

Bundles that set **playlist**, **quote category**, and an optional **board title**. Seven builtins ship ready; customs save to `quote-board-scenes.dat`.

| Builtin | Hours (MC `os.time`) | Playlist | Quotes |
|---------|----------------------|----------|--------|
| Morning Briefing | 05–11 | Elevator | TIP |
| Open World | 11–17 | Zelda | ALL |
| Ember Hours | 17–21 | RuneScape | WISDOM |
| Underground | 21–05 | Undertale | QUOTE |
| Deep Work / Raid Night / Quiet Hours | manual | various | various |

- `S` or `#scene <id>` activates; `#scene auto` toggles Minecraft daypart switching (default **off**)
- Manual `L` / `C` clears the active scene tag (keeps the playlist/filter you picked)
- Atmospheres app: Enter activate · `T` auto · `N` new · `B` clone · `R` edit custom · `D` delete

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
- **78 tracks** across elevator, Zelda-inspired, RuneScape (OST remixes + inspired), Undertale-inspired, and original playlists
- **A New Start** always plays first after boot
- Shuffle bag (no repeats until the bag empties)
- Playlists (`L` / `#playlist`): All / Elevator / Zelda-inspired / RuneScape / Undertale-inspired / Originals / Title only
- RuneScape playlist includes fan note-block remixes of actual OST tracks (Scape Main, Sea Shanty 2, Harmony, …)
- Volume control + mute; settings persist in `quote-board-settings.dat`
- **True polyphony:** simultaneous chord notes are fired in one tick (CC allows 8 `playNote`s/speaker/tick); with enough speakers, each voice gets a dedicated speaker (`3v | 4spk` in the footer)
- Interruptible playback (skip/mute/chat never get swallowed)

### Atmospheres
- Preset “radio station” modes tying music + quotes + header title together
- Optional auto daypart from Minecraft world time (`os.time`)
- Custom scenes with hour windows, editable in the Atmospheres app

### Display
- Boot splash
- Clock in the header (title swaps when a scene is active)
- **On-screen touch toolbar**: Prev / Pause / Next / Mute·Unmute / Skip / Vol / Scene / Apps
- Mirrored across all attached colour monitors
- Help overlay with session stats (uptime, quotes shown, chat captured)

### Reliability
- Single event loop (music is a coroutine) so mute/unmute and touch are not stolen by a parallel music thread
- Title track is not skipped by daypart auto on the first UI tick

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
| `quote-board-custom.dat` | Workshop customs (`text`, source, category, enabled) |
| `quote-board-scenes.dat` | Custom atmosphere scenes |
| `quote-board-settings.dat` | Volume, mute, playlist, category filter, scene auto/id |

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
