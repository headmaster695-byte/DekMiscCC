# DekMiscCC

A collection of standalone Lua scripts for [CC: Tweaked](https://tweaked.cc/) running on **Minecraft 1.21.1 / NeoForge** (CC:T 1.119.x).

Each script in `scripts/` is self-contained and can be dropped onto any compatible computer, turtle, or pocket computer without dependencies on the others.

## Compatibility

| Component | Version |
|-----------|---------|
| Minecraft | 1.21.1 |
| Mod loader | NeoForge |
| CC: Tweaked | 1.119.x |
| Lua runtime | Cobalt (Lua 5.2 compatible, select 5.3 features) |

## Repository Layout

```
DekMiscCC/
├── README.md           ← you are here
├── CONTRIBUTING.md     ← how to add and document new scripts
├── docs/
│   ├── getting-started.md  ← installing scripts on a CC computer
│   └── conventions.md      ← code style and documentation rules
└── scripts/
    └── <script-name>/      ← one directory per script
        ├── README.md       ← what it does, usage, requirements
        └── *.lua           ← script source file(s)
```

## Quick Start

See [docs/getting-started.md](docs/getting-started.md) for step-by-step instructions on getting a script onto your in-game computer.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) before adding a new script.

## License

Scripts in this repository are released under the [MIT License](LICENSE).
