# A16EEN

A16EEN is a from-scratch Linux desktop experience built around **Niri + Quickshell**.

The project is being designed as a cohesive desktop product rather than a conventional dotfile collection. The shell, interactions, visual language, services, installer, and eventually the compositor are intended to belong to A16EEN.

## Foundation

- **Niri** — Wayland compositor and window-management foundation
- **Quickshell** — desktop shell/UI layer
- **QML** — visual system
- **Rust** — future system services and compositor work
- **Wayland** — display protocol

## Current features

- Full-screen A16EEN wallpaper layer on every monitor
- Multi-monitor top bar
- Live Niri workspace and focused-window state through the Niri JSON event stream
- Application launcher backed by the system desktop-entry index
- Keyboard-searchable application filtering
- Application icons from the system icon theme
- Dashboard with clock, system load, volume and battery widgets
- Notification daemon integration with an A16EEN notification toast
- PipeWire volume status
- UPower battery status when available
- Safe, isolated A16EEN configuration
- Dedicated **A16EEN** Wayland session entry

## Wallpaper

Place your default wallpaper here:

```
quickshell/a16een/assets/wallpapers/default.webp
```

The installer copies it to:

```
~/.config/a16een/quickshell/a16een/assets/wallpapers/default.webp
```

Use a high-resolution image. The shell uses `PreserveAspectCrop`, so it fills the screen without distortion.

## Keyboard controls

```
Super + D              Application launcher
Super + P              A16EEN dashboard
Super + O              Niri overview
Super + Enter          Terminal
Super + Q              Close window
Super + H/J/K/L        Navigate
Super + 1..5           Workspaces
Super + Shift + 1..5   Move window to workspace
```

The keybindings are kept in `niri/config.kdl` and can evolve independently from the UI.

## Install

A16EEN expects a working Niri and Quickshell installation.

On Arch, the current Quickshell documentation lists a release package named `quickshell`; the `quickshell-git` AUR package tracks unreleased changes.

Then:

```sh
git clone https://github.com/Parabotx/A16EEN.git
cd A16EEN
sh scripts/install.sh
```

The installer only writes the A16EEN configuration under `~/.config/a16een` and installs the A16EEN session launcher under `/usr/local/bin` plus the session entry under `/usr/share/wayland-sessions`.

It does not overwrite `~/.config/niri/config.kdl`.

## Architecture

```
A16EEN shell
      │
   Quickshell
      │
      Niri
      │
  Wayland / Linux
```

Long-term:

```
A16EEN shell + services
          │
   A16EEN compositor
          │
        Smithay
          │
       Wayland
          │
        Linux
```

## Safety direction

Application launching is performed through Quickshell's parsed desktop-entry API rather than passing launcher input into a shell command. The shell's fixed system probes use fixed executable arguments; there is no user-input-to-shell execution path in the launcher.

A16EEN is still early software. Test it as a separate login session first and keep your existing Niri session available as a fallback.
