# Getting Started

This guide explains how to get a script from this repository onto a CC: Tweaked computer in-game.

## Prerequisites

- Minecraft 1.21.1 with NeoForge installed
- CC: Tweaked 1.119.x installed as a mod
- An in-game computer, turtle, or pocket computer placed and right-clicked to open the shell

## Methods for Loading a Script

### Method 1 — `wget` (recommended for hosted scripts)

If the script has a raw URL (e.g. from GitHub):

```
wget <raw-url> <filename>.lua
```

Example:

```
wget https://raw.githubusercontent.com/<user>/DekMiscCC/main/scripts/my-script/my-script.lua my-script.lua
```

Then run it:

```
my-script
```

### Method 2 — `pastebin get` (for Pastebin-hosted scripts)

```
pastebin get <pastebin-code> <filename>.lua
```

### Method 3 — Manual copy-paste

1. Open the script's `.lua` file in your browser or text editor.
2. Right-click the in-game computer screen → paste (or use `Ctrl+V` if your CC version supports it).
   - Some terminals require you to use the in-game `edit <filename>.lua` command and paste line by line.

### Method 4 — Shared drive / disk

1. Place a Floppy Disk in a Disk Drive adjacent to the computer.
2. Copy the `.lua` file to the disk from another computer or from the creative inventory (in creative mode).
3. On the target computer, copy from the drive:

```
copy /disk/my-script.lua my-script.lua
```

## Running a Script

Once the file is on the computer:

```
my-script
```

Or, to have it run automatically on startup, name it `startup.lua` (or add a call to it from an existing `startup.lua`).

## Updating a Script

Re-run the original `wget` or `pastebin get` command with the same filename — it will overwrite the existing file.

## Useful In-Game Commands

| Command | Description |
|---------|-------------|
| `ls` | List files in the current directory |
| `edit <file>` | Open the built-in text editor |
| `delete <file>` | Remove a file |
| `reboot` | Restart the computer (re-runs `startup.lua`) |
| `shutdown` | Power off the computer |
| `help` | Open the built-in help system |

## Further Reading

- [CC: Tweaked official documentation](https://tweaked.cc/)
- [Lua 5.2 reference manual](https://www.lua.org/manual/5.2/) — the Cobalt runtime is largely Lua 5.2 with select 5.3 additions
- [CC: Tweaked GitHub](https://github.com/cc-tweaked/CC-Tweaked)
