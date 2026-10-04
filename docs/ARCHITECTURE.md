# A16EEN Architecture

## 1. Compositor layer

Niri currently owns:

- Wayland session
- windows and focus
- scrollable tiling
- workspaces
- input bindings
- monitor/output behavior
- compositor-level effects

The A16EEN project should keep compositor configuration focused on behavior rather than visual application logic.

## 2. Shell layer

Quickshell owns the user-facing desktop:

- top-level shell panels
- launcher
- overview UI
- notifications
- control center
- media controls
- OSDs
- system widgets
- future lockscreen UI
- settings

QML is the visual language of the shell.

## 3. Service layer

System services should gradually move into small focused programs instead of one giant process.

Likely language:

- Rust for system-facing services and future compositor work
- QML/Quickshell for presentation
- shell commands only where they are the cleanest interface

## 4. Configuration

User configuration should eventually live separately from the shipped defaults.

Target:

```
~/.config/a16een/
├── theme/
├── shell/
├── services/
└── user.conf
```

The repository should contain sane defaults and upgrade-safe migration paths.

## 5. Future compositor

A16EEN should eventually be able to replace Niri with an A16EEN-owned Wayland compositor built on Smithay.

That is intentionally not part of the first milestone.

The migration path is:

```
Niri
  ↓
A16EEN shell + services
  ↓
A16EEN compositor prototype
  ↓
A16EEN compositor
```

## Design rule

**No component should become indispensable merely because it is convenient.**

We want replaceable layers, small interfaces, and an architecture that lets the project evolve without a rewrite.
