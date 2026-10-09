# A16EEN Music Dancer SVGs

Drop your five animated SVGs in this folder using these exact filenames:

- `dancer-1.svg`
- `dancer-2.svg`
- `dancer-3.svg`
- `dancer-4.svg`
- `dancer-5.svg`

On Arch, the local checkout path is:

`~/.local/share/a16een/source/quickshell/a16een/assets/music-dancers/`

The music widget chooses a random available dancer when a track starts or resumes. It unloads the SVG completely when playback pauses or the widget is disabled. Missing files are okay; if only two or three are present, it randomly chooses from those that exist.

For best compatibility, use self-contained SVGs that animate with CSS keyframes or supported SVG SMIL transform/color animations. Avoid JavaScript-driven animation or externally linked assets; those are not supported by Qt's SVG renderer.

After copying the files, run:

```bash
a16een-update
```

The updater permits only these five named SVGs as local untracked assets and will deploy them into `~/.config/a16een/quickshell/a16een/assets/music-dancers/`.
