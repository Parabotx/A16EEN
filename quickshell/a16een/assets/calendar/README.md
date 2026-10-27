# Ethiopian calendar portrait artwork

The navbar calendar's selected-day card supports these portrait collections:

- Saint Michael: the existing single portrait reference is `saint-michael.webp` in this folder.
- Saint Mary: put images inside `saint-mary/`.
- Kidane Mehret: put images inside `kidane-mehret/`.

## Where to upload portraits

Upload Saint Mary portraits to:

`quickshell/a16een/assets/calendar/saint-mary/`

Upload Kidane Mehret portraits to:

`quickshell/a16een/assets/calendar/kidane-mehret/`

The filenames can be anything descriptive, for example:

- `saint-mary/lideta.jpg`
- `saint-mary/maryam-icon-2.webp`
- `kidane-mehret/kidane-mehret.jpg`
- `kidane-mehret/kidane-mehret-2.png`

Supported formats are `.jpg`, `.jpeg`, `.png`, `.webp`, and `.avif`. Images should be placed directly inside the matching folder; subfolders inside a portrait folder are not scanned.

Whenever a Saint Mary or Kidane Mehret detail card opens, the app randomly chooses an image from that collection. When multiple files are available, it avoids showing the exact same file twice in a row when possible. Add more files at any time; no code changes or filename prefixes are required.

## Image guidance

Portrait orientation (4:5 or 3:4) works well. Keep the subject centered and leave safe margins around faces or iconography. Optimize files for fast loading and only commit artwork you have permission to redistribute.

During `a16 -u`, bundled images are copied into the runtime calendar asset folder while preserving their subfolder paths:

`~/.config/a16een/quickshell/a16een/assets/calendar/saint-mary/`

`~/.config/a16een/quickshell/a16een/assets/calendar/kidane-mehret/`

The installer preserves existing runtime files, except when a bundled file has the same relative path and filename. If a portrait collection has no supported images yet, the detail card falls back to its legacy single-image reference and displays a placeholder if that file is unavailable.
