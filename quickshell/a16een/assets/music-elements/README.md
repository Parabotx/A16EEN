# Bundled music artwork

Place repository-shipped animated artwork in this folder. A16EEN supports:

- `.webp` animated images, decoded with Qt Quick's `AnimatedImage`
- `.webm` video stickers, played silently with Qt Multimedia

The installer copies both file types, including files in subfolders, to the
deployed music-artwork library. The music widget randomly selects from the
combined installed and personal collections and only plays the animation while
music is playing.

This folder is for artwork tracked in GitHub and shipped to every user. Personal
artwork belongs in `~/Pictures/a16een/music-elements/`; updates never remove or
overwrite files in that personal folder.
