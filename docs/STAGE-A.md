# A16EEN Stage A — Foundation Hardening

Stage A is the non-negotiable foundation milestone for A16EEN. Features from later stages must not remove or bypass these guarantees.

## Stage A checklist

- [ ] 1. Session reliability
- [ ] 2. Niri validation
- [ ] 3. Multi-monitor
- [ ] 4. XWayland
- [ ] 5. Portals
- [ ] 6. Audio
- [ ] 7. Bluetooth
- [ ] 8. Network
- [ ] 9. Brightness
- [ ] 10. Lock / logout / reboot / power
- [ ] 11. App compatibility
- [ ] 12. Installer recovery
- [ ] 13. Update / rollback
- [ ] 14. Doctor diagnostics

## Current implementation

### Session reliability
A16EEN uses `NIRI_CONFIG` instead of replacing `XDG_CONFIG_HOME`. This keeps normal application configuration in the user's standard `~/.config` hierarchy. The Quickshell UI runs through `a16een-shell`, a bounded supervisor that can recover from transient shell crashes without taking Niri or application windows down.

### Niri validation
The installer validates the staged Niri configuration before deploying it. `a16een-doctor` validates the installed configuration independently.

### Multi-monitor
Wallpaper and top-bar shell components are instantiated per detected Quickshell screen. Live Niri output inspection is part of the doctor.

### XWayland
Niri's current xwayland-satellite integration is enabled explicitly in the A16EEN config. Niri launches and restarts the satellite on demand for X11 clients when a supported binary is present.

### Portals
The installer includes `xdg-desktop-portal` and `xdg-desktop-portal-gtk`, and installs an A16EEN-specific portal preference without overwriting an existing user preference.

### Audio / Bluetooth / Network / Brightness
The required command-line interfaces are installed by the dependency set and are inspected by the doctor. The doctor distinguishes missing software from hardware/service state so a machine without a Bluetooth controller, for example, is not treated as a broken installation.

### Lock / logout / reboot / power
A16EEN ships fixed command paths/argument lists for these actions. Reboot and poweroff require a second confirmation click.

### App compatibility
The launcher uses XDG desktop entries and Quickshell's parsed desktop-entry commands instead of executing arbitrary search text. X11 compatibility is provided through Niri's xwayland-satellite integration, while portal support covers sandboxed applications.

### Installer recovery
Revision-changing deployments back up the current A16EEN configuration before replacement. Deployment validates the compositor config before the live files are changed.

### Update / rollback
`a16een-update` remains fast-forward-only for normal updates. `a16een-update --status` reports the installed/source state and `a16een-update --rollback` restores the latest known-good revision recorded by the installer.

### Doctor diagnostics
`a16een-doctor` checks session prerequisites, configuration validation, outputs, XWayland, portals, audio, Bluetooth, network, brightness, session controls, application discovery, recovery state, update state, and installed A16EEN files.

## What still requires live hardware testing

The repository can enforce the software-side foundation, but real completion also requires testing on physical machines and multiple configurations:

- fresh Arch installations
- existing Arch desktops
- laptop and desktop GPUs
- multiple monitors and hot-plugging
- X11 applications and games
- Flatpak applications
- suspend/resume
- Bluetooth hardware
- network-manager states
- backlight hardware
- login/logout/reboot/power cycles
- interrupted installs and failed updates
- long-running session stability

A feature is not considered Stage A complete until both the implementation and live compatibility testing pass.
