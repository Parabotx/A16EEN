# A16EEN

A16EEN is a from-scratch Linux desktop experience built around **Niri + Quickshell**.

The project is being designed as a cohesive desktop product rather than a conventional dotfile collection. The shell, interactions, visual language, services, installer, and eventually the compositor are intended to belong to A16EEN.

## Foundation

- **Niri** — Wayland compositor and window-management foundation
- **Quickshell** — desktop shell/UI layer
- **QML** — visual system
- **Rust** — future system services and compositor work
- **Wayland** — display protocol

## Current desktop features

- Full-screen wallpaper layer on every monitor
- Multi-monitor A16EEN top bar
- Live workspace and focused-window state from Niri's JSON event stream
- Keyboard-searchable application launcher with system application icons
- Dashboard with clock, system load, volume, battery, and media controls
- MPRIS media controls for compatible players
- Notification daemon integration
- Network connection indicator
- Bluetooth power indicator
- Safe session controls with confirmation for reboot and power-off
- Volume, microphone, media, and brightness keybindings
- Dedicated **A16EEN** Wayland session entry
- Isolated configuration under `~/.config/a16een/`

## Wallpaper

Put your default wallpaper here:

```
quickshell/a16een/assets/wallpapers/default.png
```

The installer copies it into the installed A16EEN shell tree. Use a high-resolution image; the shell preserves the aspect ratio and crops to fill the screen.

## One-command installation

Install or update A16EEN from one terminal command:



```sh
curl -fsSL https://raw.githubusercontent.com/Parabotx/A16EEN/main/install.sh | bash
```

The bootstrap installs Git only when it is missing, keeps a persistent A16EEN source checkout under `~/.local/share/a16een/source`, and fast-forwards that checkout when a newer A16EEN commit exists. It does not reinstall an unchanged A16EEN checkout.

The project installer installs only missing A16EEN dependencies, backs up the previous A16EEN configuration before a revision change, deploys the new files, and leaves the user's normal Niri configuration untouched.

Current automatic dependencies include:

```
niri
quickshell
foot
fuzzel
brightnessctl
playerctl
pipewire
wireplumber
upower
swaylock
xwayland-satellite
xdg-desktop-portal-gtk
networkmanager
bluez
bluez-utils
nm-connection-editor
```

Niri and Quickshell are available as official Arch packages.

## Updating

The normal installer is also the updater:

```sh
curl -fsSL https://raw.githubusercontent.com/Parabotx/A16EEN/main/install.sh | bash
```

After installation, the shorter updater command is:

```sh
a16een-update
```

Updates are fast-forward-only. If the local A16EEN source has uncommitted changes, the updater stops instead of overwriting them. Previous A16EEN runtime configuration revisions are backed up under `~/.local/state/a16een/backups/`.

Use:

```sh
a16een-doctor
```

to run read-only diagnostics, including Niri configuration validation.

## Manual installation from a clone

```sh
git clone https://github.com/Parabotx/A16EEN.git
cd A16EEN
bash scripts/install.sh
```

## Keyboard controls

```
Super + D              Application launcher
Super + P              A16EEN dashboard
Super + O              Niri overview
Super + Return        Terminal
Super + Q              Close window
Super + H/J/K/L        Navigate
Super + 1..5           Workspaces
Super + Shift + 1..5  Move window to workspace
Super + Alt + L        Lock screen
```

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

Niri is the first compositor target, not the final boundary of the project.

## Safety direction

Application launching uses Quickshell's parsed desktop-entry command rather than treating launcher text as a shell command. System actions use fixed executable argument lists, and destructive session actions require a second confirmation click.

The installer does not execute package names or commands supplied by the user. It uses a fixed repository URL and a fixed dependency list. It never deletes the user's normal Niri configuration.

A16EEN is still early software. Keep your existing desktop session available as a fallback while testing new builds.
