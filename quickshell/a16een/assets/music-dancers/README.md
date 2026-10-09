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

These must be **Lottie animation JSON exports**, not arbitrary JSON. Qt's Lottie player supports a subset of Lottie; shape-layer animations are the safest choice. Avoid expressions and external image/font assets where possible. Keep animations lightweight because they are software-rendered.

The installer includes Arch Linux's `qt6-lottie` package, which provides the `Qt.labs.lottieqt` QML module used by A16EEN.
