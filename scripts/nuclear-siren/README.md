# nuclear-siren

Plays a wailing nuclear/civil-defence siren alarm with a flashing visual warning for five minutes.

## Requirements

| Requirement | Details |
|-------------|---------|
| Computer type | Any (Regular, Advanced, Pocket, or Turtle shell) |
| Speaker peripheral | **Optional but strongly recommended** — without it the alarm is visual only |
| Colour display | Optional — an Advanced Computer or Advanced Monitor greatly improves the flashing red warning display |

## How it works

**Audio** — A `speaker` peripheral plays the `"bit"` instrument sweeping continuously from pitch 0 → 24 → 0 (one semitone per game tick, ~0.05 s/step). At pitches 20–24 a quieter `"bell"` layer is mixed in for a piercing top-note. The complete wail cycle is approximately 2.5 seconds; it repeats for the full five-minute duration.

**Visual** — The terminal (or monitor, if redirected) flashes red/black every 0.5 seconds and displays a centred warning with a live MM:SS countdown.

**Stop early** — Press `Ctrl+T` at any time to silence the alarm. The terminal is always cleaned up, even on early exit.

## Installation

Download the script directly from the in-game shell:

```
wget https://raw.githubusercontent.com/headmaster695-byte/DekMiscCC/main/scripts/nuclear-siren/nuclear-siren.lua nuclear-siren.lua
```

## Usage

```
nuclear-siren
```

No arguments needed. The alarm starts immediately and runs for five minutes.

## Configuration

Open `nuclear-siren.lua` in the built-in editor (`edit nuclear-siren.lua`) and change the values in the **Configuration** section near the top:

| Variable | Default | Description |
|----------|---------|-------------|
| `DURATION` | `5 * 60` (300 s) | Total alarm length in seconds |
| `INSTRUMENT` | `"bit"` | Note-block instrument for the siren wail |
| `VOLUME` | `3.0` | Speaker volume (0.0 – 3.0) |
| `SWEEP_DELAY` | `0.05` | Seconds per semitone step (minimum 1 game tick = 0.05 s) |
| `FLASH_INTERVAL` | `0.5` | Seconds between display colour flashes |

### Instrument options

Any CC: Tweaked note-block instrument name is valid: `"harp"`, `"basedrum"`, `"snare"`, `"hat"`, `"bass"`, `"flute"`, `"bell"`, `"guitar"`, `"chime"`, `"xylophone"`, `"iron_xylophone"`, `"cow_bell"`, `"didgeridoo"`, `"bit"`, `"banjo"`, `"pling"`.

`"bit"` (8-bit buzz) and `"flute"` (wind) produce the most convincing siren tones.

## Redirecting output to a monitor

To send the display to a monitor instead of (or alongside) the computer screen, wrap the call in a `term.redirect`:

```lua
-- place this in a small startup.lua on the computer
local mon = peripheral.find("monitor")
assert(mon, "No monitor found")
mon.setTextScale(0.5)  -- shrink text so more fits on screen
term.redirect(mon)
os.run({}, "nuclear-siren")
term.restore()
```

## Notes

- The script uses `parallel.waitForAll` to run sound and display concurrently; both stop cleanly when the five minutes expire.
- `speaker.playNote` is limited to **8 notes per game tick** by CC: Tweaked. This script uses at most 2 notes per tick (one `"bit"` + one `"bell"` at peak pitch), well within that limit.
- Volume `3.0` is the maximum and allows the speaker to be heard from the greatest distance; it does not necessarily mean loudest to nearby players.
