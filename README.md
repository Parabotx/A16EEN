# A16EEN

A16EEN is a from-scratch Linux desktop experience built around Niri + Quickshell.

The goal is not to make another dotfile collection. A16EEN is intended to become a cohesive desktop product with its own visual language, shell, services, interactions, installer, and eventually a custom Wayland compositor.

## Foundation

- **Niri** — Wayland compositor and window-management foundation
- **Quickshell** — desktop shell/UI layer
- **QML** — visual system and interactive components
- **Rust** — future system services and compositor work
- **KDL** — Niri configuration
- **Wayland** — display protocol

## Repository layout

```
A16EEN/
├── niri/
│   └── config.kdl
├── quickshell/
│   └── shell.qml
├── session/
│   └── a16een.desktop
├── scripts/
│   ├── install.sh
│   └── start-a16een
├── docs/
│   └── ARCHITECTURE.md
├── themes/
└── .gitignore
```

## Current milestone

The first milestone is deliberately small:

1. Boot into an A16EEN Wayland session.
2. Start Niri with an A16EEN-owned configuration.
3. Start the Quickshell layer automatically.
4. Provide a minimal but visually intentional shell.
5. Keep the architecture ready for a much larger desktop system.

A16EEN stores its configuration under `~/.config/a16een/` so it does not replace an existing Niri configuration.

## Install

After cloning the repository:

```sh
cd A16EEN
sh scripts/install.sh
```

The installer requires an existing working Niri and Quickshell installation.

## Long-term direction

```
A16EEN Shell
     │
 Quickshell
     │
    Niri
     │
  Smithay / future A16EEN compositor
     │
   Wayland
     │
   Linux
```

Niri is the starting compositor, not the final boundary of the project.

## Status

Early foundation — the architecture and visual system are intentionally expected to evolve rapidly.
