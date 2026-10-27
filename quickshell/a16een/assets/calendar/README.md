# Ethiopian calendar portrait artwork

The navbar calendar's selected-day card supports portrait artwork for these commemorations:

- `saint-michael.webp` — Saint Michael on the 12th
- `kidane-mehret.webp` — Kidane Mehret on the 16th
- `saint-mary.jpg`, `saint-mary-2.jpg`, `saint-mary-anything.jpg` — Maryam portraits

## Add multiple Maryam images

Upload your Maryam images into this same folder:
`quickshell/a16een/assets/calendar/`

Use the filename prefix `saint-mary` and the `.jpg` extension, for example:

- `saint-mary.jpg`
- `saint-mary-2.jpg`
- `saint-mary-lideta.jpg`

The detail card scans the installed calendar assets folder and randomly selects one of the matching `.jpg` or `.jpeg` files whenever a Maryam portrait card opens. If more than one image is available, it avoids choosing the same image twice in a row when possible. No code change is needed when you add more matching images.

## Image guidance

Portrait orientation (4:5 or 3:4) works well. Keep the subject centered and leave safe margins around faces or iconography. Optimize files for fast loading and only commit artwork you have permission to redistribute.

During `a16 -u`, bundled assets are copied into:
`~/.config/a16een/quickshell/a16een/assets/calendar/`

Existing runtime files are preserved, except that a bundled file with the same filename replaces the local copy. The card shows a placeholder if the configured image is not present.
