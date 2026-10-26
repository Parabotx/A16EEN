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

After installing A16EEN, the same files are copied to:
`~/.config/quickshell/a16een/assets/calendar/`

The installer only copies recognized image files into this directory and does not
delete other local files, so locally added artwork can remain there across updates.
The detail card shows a subtle placeholder until each expected image is available.

Respect the source artwork's license and use images that you have permission to
redistribute in a public dotfiles repository.
