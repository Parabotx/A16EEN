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
- A16EEN command center with slash-first command search
- Visual wallpaper picker with live previews
- Separate built-in and personal wallpaper collections
- MPRIS media controls for compatible players
- Notification daemon integration
- Network connection indicator
- Bluetooth power indicator
- Searchable 24-hour text clipboard history with one-line previews and click-to-copy
- Safe session controls with confirmation for reboot and power-off
- GTKLock password-entry lock screen with visible cursor, live time/date, and the current wallpaper (including a captured frame for animated backgrounds)
- Volume, microphone, media, and brightness keybindings
- Dedicated **A16EEN** Wayland session entry
- Lightweight curated font set for UI, display, text, and mono use
- Persistent user wallpaper collection with `a16 wallpaper`
- Isolated configuration under `~/.config/a16een/`

## Clipboard history

The navbar utilities panel includes a searchable clipboard history for copied text. A16EEN watches the Wayland text clipboard, moves repeated items back to the top, and removes entries after 24 hours. Each row shows a single-line preview; click an item to copy it back, or remove one item or clear the history.

History stays on the local machine at `~/.local/state/a16een/clipboard-history.json`. The file is stored with user-only permissions. Clipboard history is text-only; copied text may include sensitive information, so it remains available for up to 24 hours unless you remove it earlier.

## Icon Themes

A16EEN includes a graphical icon-theme switcher available from the Command Center with:

    /icons

The launcher already resolves application icons through Quickshell's system icon theme. A16EEN persists the selected theme and reloads its shell automatically when a theme changes.

Curated themes include **System Default**, **Papirus**, **Papirus Dark**, **Breeze**, **Elementary**, **Tela Circle**, **Tela Circle Blue**, **Tela Circle Dracula**, and **Tokyo Night**. Icon themes are now installed on demand: normal A16EEN updates do not install large icon packs. The graphical /icons screen installs only the theme you choose; Tokyo Night is downloaded from its upstream `TokyoNight-SE` release the first time it is selected. Compatible GTK applications and file managers can also use the selected icon theme, so application and folder icons stay consistent.

CLI equivalents:

    a16 icons theme list
    a16 icons theme current
    a16 icons theme set papirus-dark
    a16 icons theme cleanup

Existing applications may need to be restarted before they redraw with the new icon theme.

## Workspace Presets

A16EEN includes **Workspace Presets** for manually opening a complete working setup without adding anything to system startup.

Open the graphical builder from the Command Center with:

    /presets

Create a preset such as **AGAZ**, then choose its applications one at a time. After each app is selected, A16EEN asks which named workspace should receive it:

    01  HOME
    02  CODE
    03  WEB
    04  COMMS
    05  STUDIO
    06  MUSIC

Save the preset, and it appears as a reusable card with **OPEN**, **EDIT**, and **REMOVE** actions. Opening a preset launches each selected application, waits for its window to appear, explicitly places that window on the requested named workspace through Niri IPC, and finally returns focus to the workspace you were using before the preset was opened. Niri supports named workspaces and window-to-workspace IPC actions, which A16EEN uses for this flow.

Preset data is stored locally in:

    ~/.local/state/a16een/workspace-presets.json

The feature only uses applications exposed through the XDG desktop-entry index. A16EEN stores the parsed desktop-entry command rather than asking users to type arbitrary shell commands, keeping the graphical workflow controlled and predictable. Quickshell exposes both the application index and its parsed DesktopEntry.command for this purpose.

The CLI entry point is:

    a16 presets

## Wallpaper

A16EEN keeps two wallpaper collections.

Built-in A16EEN wallpapers live in the GitHub repository at:

```
quickshell/a16een/assets/wallpapers/
```

Put any supported static wallpaper there. The filename does not matter. Keep:

```
default.png
```

as the first-launch default.

Personal wallpapers live in:

```
~/Pictures/a16een/
```

A16EEN creates this folder during installation. User files are never overwritten by A16EEN updates.

Use **Super + /**, then choose:

```
/wallpaper
```

A16EEN opens a clean visual picker with minimal previews and the real image filenames. Select any wallpaper to make it active. Selecting `default.png` returns to the A16EEN default.

The wallpaper manager also supports:

```
a16 wallpaper list
a16 wallpaper current
a16 wallpaper current-path
a16 wallpaper catalog
a16 wallpaper set <filename>
a16 wallpaper set <builtin|custom> <filename>
a16 wallpaper next
a16 wallpaper previous
a16 wallpaper reset
```

Supported static image formats include PNG, JPG, JPEG, WEBP, BMP, TIFF, TGA, SVG, PPM, PGM, PBM, XPM, and XBM. Animated GIF and animated WebP files play in the Animated tab; still WebP images remain in the static Wallpaper tab. MP4, WEBM, MOV, M4V, and MKV wallpapers use Qt Multimedia's video renderer, loop silently, and pause or resume with A16EEN's desktop animation policy. Video previews play muted only while their tile is hovered, so opening the picker does not start every video at once. The installed `qt6-imageformats` and `qt6-multimedia` modules provide the image and video loading backends.

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
gtklock
ffmpeg
xwayland-satellite
xdg-desktop-portal-gtk
networkmanager
bluez
bluez-utils
nm-connection-editor
curl
xdg-desktop-portal
xdg-utils
qt6-imageformats
qt6-svg
```

Niri and Quickshell are available as official Arch packages.

## Updating

The normal installer is also the updater. Running the command again checks GitHub and updates only when A16EEN changed:

```sh
curl -fL https://raw.githubusercontent.com/Parabotx/A16EEN/main/install.sh -o /tmp/a16een-install.sh && bash /tmp/a16een-install.sh && rm -f /tmp/a16een-install.sh
```

After installation, update with the short flag:

```sh
a16 -u
```

You can also use the dedicated updater command:

```sh
a16-update
```

The updater supports concise flags too: `a16-update -s` shows revision status, `a16-update -r` rolls back, and `a16-update -h` shows its help. The matching A16 shortcuts are `a16 -s` for status and `a16 -b` for rollback.

Use `-y` only when you intentionally want to skip the rollback confirmation.


Updates are fast-forward-only. If the local A16EEN source has uncommitted changes, the updater stops instead of overwriting them. Previous A16EEN runtime configuration revisions are backed up under `~/.local/state/a16een/backups/`.

Use:

```sh
a16 doctor
```

to run read-only diagnostics, including Niri configuration validation.

## Manual installation from a clone

```sh
git clone https://github.com/Parabotx/A16EEN.git
cd A16EEN
bash scripts/install.sh
```

## A16EEN visual resources

A16EEN keeps its built-in asset set small and reuses open-source libraries when a feature needs a specialized visual. The curated sources and their licenses are documented in [docs/RESOURCES.md](docs/RESOURCES.md).

Useful sources include Lucide, Iconoir, Phosphor, OpenMoji, Twemoji, Lottie, Rive, and selected open-source typefaces. We do not vendor entire repositories into the desktop.

### Wallpaper locations

Built-in A16EEN wallpapers:

```
quickshell/a16een/assets/wallpapers/
```

Personal wallpapers:

```
~/Pictures/a16een/
```

A16EEN preserves the user's personal collection across updates. Root-level image files from the earlier wallpaper setup are also imported automatically during installation so existing wallpapers are not lost.

## A16EEN icon system

A16EEN uses two icon sources:

- application icons come from each application's XDG desktop entry, so the real app icon is shown in the dock and launcher;
- A16EEN's own interface icons use pinned Lucide SVG assets.

Lucide is used as a generic UI icon source because it provides a large open-source SVG collection. A16EEN pins the icon source to a known release rather than downloading from a moving branch. The installer refreshes the runtime icon set when A16EEN is installed or updated, while bundled SVG fallbacks keep the dock usable when the network is unavailable. citeturn175664search1turn815170search0

You can manually refresh the icon set with:

```sh
a16 icons
```

## A16 terminal command

A16 installs a unified `a16` command for terminal control:

```sh
a16 launcher
a16 dashboard
a16 overview
a16 close
a16 maximize
a16 fullscreen
a16 float
a16 center
a16 workspace 2
a16 lock
a16 logout
a16 reboot
a16 poweroff
a16 suspend
a16 hibernate
a16 volume up
a16 volume down
a16 volume mute
a16 brightness up
a16 brightness down
a16 media toggle
a16 media next
a16 screenshot
a16 screenshot-screen
a16 screenshot-window
a16 restart-shell
a16 -u
a16 -b
a16 -d
a16 -s
```

Quick shortcuts include `a16 -h` for help, `a16 -u` to update, `a16 -r` to restart the shell, `a16 -s` for status, `a16 -d` for diagnostics, `a16 -b` for rollback, and `a16 -v` for version information. Natural two-word aliases include `a16 shell restart`, `a16 app open`, `a16 control open`, `a16 screen shot`, and `a16 system update`.

Reboot and power-off require confirmation unless `--yes` / `-y` is explicitly supplied. Logout uses Niri's IPC action, which retains Niri's own confirmation behavior. The CLI keeps desktop actions behind fixed commands and arguments rather than accepting arbitrary shell input.

## Keyboard controls

```
Super + Space          Application launcher
Super + /              A16EEN command center
Super + P              A16EEN dashboard
Super + O              Niri overview
Super + Return         Terminal
Super + X              Close window
Super + F              Fullscreen toggle
Super + T              Exit fullscreen
Super + M              Maximize column
Super + H/J/K/L        Navigate
Super + 1..6           Workspaces
Super + Shift + 1..6  Move window to workspace
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
