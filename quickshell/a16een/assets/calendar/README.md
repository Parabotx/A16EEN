# Ethiopian calendar portrait artwork

The navbar calendar's selected-day card can load portrait-format images for these
monthly commemorations:

- `saint-michael.webp` — the 12th day
- `kidane-mehret.webp` — the 16th day
- `saint-mary.webp` — the 21st day

Place bundled images in this directory in the repository:
`quickshell/a16een/assets/calendar/`

Recommended format: WebP, portrait orientation (for example 4:5 or 3:4), with
the subject centered and enough safe margin around faces or iconography to tolerate
cropping. Keep image files optimized for quick loading.

For personal artwork, the easiest place is the installed runtime directory:
`~/.config/a16een/quickshell/a16een/assets/calendar/`

You can copy the three files there directly; the detail card reads them from that
location. During install/update, bundled image files are copied from the repository directory
above into this runtime folder. Existing files in the runtime calendar folder are
preserved, except that a bundled file with the same name replaces the local copy.
To publish shared defaults for all users, add the images to the repository directory
above and commit them to `main` before users run `a16 -u`.

The detail card shows a subtle placeholder until each expected image is available.

Respect the source artwork's license and use images that you have permission to
redistribute in a public dotfiles repository.
