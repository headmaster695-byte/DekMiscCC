# Contributing to DekMiscCC

Thanks for adding a new script! Follow these steps to keep things tidy.

## Adding a New Script

### 1. Create a directory under `scripts/`

Use a short, lowercase, hyphen-separated name that describes what the script does.

```
scripts/
└── my-script-name/
    ├── README.md
    └── my-script-name.lua   ← entry-point file
```

Multi-file scripts (e.g. a library plus a main program) are fine — just keep everything inside the same subdirectory.

### 2. Write the script

Follow the style guide in [docs/conventions.md](docs/conventions.md).

### 3. Write `scripts/<name>/README.md`

Every script directory **must** have a `README.md` with at least these sections:

```markdown
# <Script Name>

One-sentence description.

## Requirements

- Computer type (regular / advanced / turtle / pocket)
- Peripherals needed (e.g. modem, monitor, inventory)
- Any other scripts or APIs this depends on

## Installation

How to get the file onto the in-game computer.
(Copy the wget / pastebin command here once the script is hosted.)

## Usage

How to run it and any runtime arguments.

## Configuration

List any variables near the top of the script that the user is expected to edit.
```

### 4. Open a pull request

Commit your `scripts/<name>/` directory, push, and open a PR against `main`.  
One PR per script keeps reviews focused.

## Checklist

Before submitting:

- [ ] Script runs without errors in a vanilla CC:T 1.119.x / 1.21.1 NeoForge environment
- [ ] `scripts/<name>/README.md` covers all sections above
- [ ] Code follows the style in [docs/conventions.md](docs/conventions.md)
- [ ] No hardcoded world-specific values (coordinates, dimension names, player names) without a clear config section
