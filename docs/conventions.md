# Code Style and Conventions

All Lua scripts in this repository follow the rules below. Consistency makes it easier to read, debug, and share scripts.

## Runtime Target

Scripts target **CC: Tweaked 1.119.x on Minecraft 1.21.1 / NeoForge**.  
The Cobalt runtime is compatible with **Lua 5.2**, plus a subset of Lua 5.3 features (integer division `//`, bitwise operators, `utf8` library, `table.move`, `math.tointeger`).  
Do **not** rely on Lua 5.4 features (generalized `for`, `<close>` variables, etc.).

## File Header

Every `.lua` entry-point file must begin with a standard header block:

```lua
-- <Script Name>
-- Author: <your name / handle>
-- CC:T version: 1.119.x | MC: 1.21.1 | Loader: NeoForge
-- Description: One-sentence summary of what the script does.
--
-- Usage: <how to invoke it, including any arguments>
```

Library files shared within a multi-file script should include the same header with `-- Role: library` appended.

## Formatting

- **Indentation**: 2 spaces (no tabs).
- **Line length**: keep lines under 100 characters where possible.
- **Blank lines**: one blank line between top-level functions; two blank lines between major logical sections.
- **Semicolons**: omit statement-ending semicolons (Lua does not require them).

## Naming

| Kind | Convention | Example |
|------|-----------|---------|
| Local variables | `camelCase` | `itemCount` |
| Module-level / global constants | `SCREAMING_SNAKE_CASE` | `MAX_RETRIES` |
| Functions | `camelCase` | `moveForward()` |
| Files | `kebab-case.lua` | `my-script.lua` |
| Directories under `scripts/` | `kebab-case` | `scripts/my-script/` |

## Configuration Variables

If a user is expected to change any values, group them at the very top of the file under the header, clearly separated:

```lua
-- ============================================================
-- Configuration — edit these values before running
-- ============================================================
local MONITOR_SIDE = "right"   -- side the monitor is attached to
local POLL_INTERVAL = 5        -- seconds between updates
-- ============================================================
```

## Error Handling

- Prefer `assert()` for invariants that must hold for the script to function.
- Use `pcall()` / `xpcall()` around any I/O that can fail (peripheral calls, network, file access).
- Always print a human-readable message before terminating on error:

```lua
local ok, err = pcall(riskyOperation)
if not ok then
  printError("Failed: " .. tostring(err))
  return
end
```

## Peripherals

- Always check that a peripheral exists before using it:

```lua
local mon = peripheral.find("monitor")
assert(mon, "No monitor found. Attach one and reboot.")
```

- Wrap peripheral calls in `pcall` if losing the peripheral mid-run is possible.

## Loops and Coroutines

- Prefer `os.sleep(n)` over busy-wait loops when waiting for time to pass.
- For event-driven scripts use `os.pullEvent()` or `os.pullEventRaw()` (the latter is required if you need to catch `terminate`).
- Avoid `while true do` without at least one `os.sleep()` or `os.pullEvent()` to yield control back to the OS.

## Comments

- Write comments that explain **why**, not **what**.
- Avoid restating what the code already makes obvious.
- Use `--` for single-line comments; block comments (`--[[ ... ]]`) are fine for temporarily disabling code sections.

## Script Termination

Scripts should clean up after themselves when they exit:

- Restore terminal colours (`term.setTextColour(colours.white)`, `term.setBackgroundColour(colours.black)`).
- Clear the screen if the script took over the display.
- Call `peripheral.unwrap()` is not needed — just stop using the peripheral reference.
