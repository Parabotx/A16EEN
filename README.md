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
- Multi-monitor floating A16EEN dock
- Live workspace state from Niri's JSON event stream
- Keyboard-searchable application launcher with system application icons
- Centered white application launcher with searchable grid and system application icons
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
curl -fL https://raw.githubusercontent.com/Parabotx/A16EEN/main/install.sh -o /tmp/a16een-install.sh && bash /tmp/a16een-install.sh && rm -f /tmp/a16een-install.sh
```

The bootstrap is interactive by default. It shows what it will do, asks before installing A16EEN's dependency set, keeps a persistent source checkout under `~/.local/share/a16een/source`, and fast-forwards that checkout when a newer A16EEN commit exists. It does not reinstall an unchanged A16EEN checkout. Use `--non-interactive` for automation.

When dependencies are missing, the project installer uses Arch's normal full-sync transaction (`pacman -Syu --needed`) instead of performing a partial package upgrade. If the transaction fails because a mirror/database is temporarily out of sync, the interactive installer offers one forced database refresh and retry. Existing dependencies are not reinstalled.

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
curl
xdg-desktop-portal
xdg-utils
```

Niri and Quickshell are available as official Arch packages.

## Updating

The normal installer is also the updater. Running the command again checks GitHub and updates only when A16EEN changed:

```sh
curl -fL https://raw.githubusercontent.com/Parabotx/A16EEN/main/install.sh -o /tmp/a16een-install.sh && bash /tmp/a16een-install.sh && rm -f /tmp/a16een-install.sh
```

After installation, the shorter updater command is:

```sh
a16een-update
```

Inspect the current revision state and rollback availability:

```sh
a16een-update --status
```

Roll back to the latest known-good revision:

```sh
a16een-update --rollback
```

Use `-y` only when you intentionally want to skip the rollback confirmation.


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

## A16EEN icon system

A16EEN uses two icon sources:

- application icons come from each application's XDG desktop entry, so the real app icon is shown in the dock and launcher;
- A16EEN's own interface icons use pinned Lucide SVG assets.

Lucide is used as a generic UI icon source because it provides a large open-source SVG collection. A16EEN pins the icon source to a known release rather than downloading from a moving branch. The installer refreshes the runtime icon set when A16EEN is installed or updated, while bundled SVG fallbacks keep the dock usable when the network is unavailable. citeturn175664search1turn815170search0

You can manually refresh the icon set with:

```sh
a16een icons
```

## A16EEN terminal command

A16EEN installs a unified `a16een` command for terminal control:

```sh
a16een launcher
a16een dashboard
a16een overview
a16een close
a16een maximize
a16een fullscreen
a16een float
a16een center
a16een workspace 2
a16een lock
a16een logout
a16een reboot
a16een poweroff
a16een suspend
a16een hibernate
a16een volume up
a16een volume down
a16een volume mute
a16een brightness up
a16een brightness down
a16een media toggle
a16een media next
a16een screenshot
a16een screenshot-screen
a16een screenshot-window
a16een restart-shell
a16een update
a16een rollback
a16een doctor
a16een status
```

Reboot and power-off require confirmation unless `--yes` / `-y` is explicitly supplied. Logout uses Niri's IPC action, which retains Niri's own confirmation behavior. The CLI keeps desktop actions behind fixed commands and arguments rather than accepting arbitrary shell input.

## Keyboard controls

```
Super + A              Application launcher
Super + P              A16EEN dashboard
Super + O              Niri overview
Super + Return         Terminal
Super + X              Close window
Super + F              Fullscreen toggle
Super + T              Fullscreen toggle
Super + M              Maximize column
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

Application launching uses the XDG desktop-entry index exposed by Quickshell. That means A16EEN can launch applications regardless of whether they came from pacman or another source, provided the application installs a valid `.desktop` entry in an XDG application directory. The desktop-entry specification defines those application directories through `$XDG_DATA_DIRS/applications/`. Quickshell exposes visible Application entries through `DesktopEntries.applications` and provides a parsed command plus `execute()` for launching them. Apps that do not install a desktop entry (for example a bare executable or unintegrated AppImage) are intentionally not auto-executed from arbitrary launcher text. citeturn964132search2turn105124search0turn105124search9 System actions use fixed executable argument lists, and destructive session actions require a second confirmation click.

The installer does not execute package names or commands supplied by the user. On Arch, installing new packages through pacman is intentionally a full-sync operation because Arch does not support partial upgrades. It uses a fixed repository URL and a fixed dependency list. It never deletes the user's normal Niri configuration.

A16EEN is still early software. Keep your existing desktop session available as a fallback while testing new builds.

## Stage A — Foundation hardening

Stage A is the gate for future feature work. The current repository includes session-environment isolation, staged Niri validation, resilient shell supervision, Niri's XWayland integration, portal setup, foundation diagnostics, configuration backups, and safe update/rollback tooling. The remaining Stage A work is live hardware and compatibility verification; see [docs/STAGE-A.md](docs/STAGE-A.md).
