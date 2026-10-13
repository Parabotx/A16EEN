# Bundled music artwork

Place repository-shipped animated artwork in this folder. A16EEN accepts:

- `.webm` transparent video stickers (source of truth; audio is ignored)
- `.webp` animated images

The installer copies both file types, including files in subfolders, to the
deployed music-artwork library. Personal files belong in
`~/Pictures/a16een/music-elements/`; updates never remove or overwrite them.

For alpha-capable WebM stickers, A16EEN uses FFmpeg to prepare an RGBA animated
WebP cache at 192×192 and 12 fps. This is an internal rendering format only:
the committed and personal sources stay WebM. The cache is limited to four
prepared animations under `~/.cache/a16een/music-elements/`; unused entries
are removed as the working set rotates. The animation remains paused unless
music is playing and its on-screen area is not covered by a normal Niri window.
