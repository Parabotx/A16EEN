# A16EEN Music Player — Lottie dancers

These five optional Lottie animations are bundled with A16EEN for every user. Upload your animation JSON files **to this GitHub folder**, not into a local-only folder:

`quickshell/a16een/assets/music-dancers/`

Use exactly these filenames:

- `dancer-1.json`
- `dancer-2.json`
- `dancer-3.json`
- `dancer-4.json`
- `dancer-5.json`

## Add the files on GitHub

Open the repository's `quickshell/a16een/assets/music-dancers/` folder, choose **Add file → Upload files**, upload the five JSON files using the names above, then commit the changes to `main`.

The installer copies these committed files to each user's `~/.config/a16een/quickshell/a16een/assets/music-dancers/` directory. The music widget randomly chooses from the files that exist while playback is running. If playback pauses or the widget is disabled, the Lottie player is destroyed so it stops animating.

## Lottie compatibility

The five bundled dancer files are generated as lightweight **shape-layer-only** animations sized for the 98×76 music-card stage. They intentionally avoid pre-compositions, image/text assets, expressions, masks, and unsupported layer types because Qt's `LottieAnimation` renderer does not implement the full Lottie specification.

When replacing a dancer, keep it shape-only, keep the canvas close to 98×76, and check that it contains no `assets`, no `chars`, and only `ty: 4` shape layers. A valid JSON file is not automatically compatible with Qt's Lottie renderer.
