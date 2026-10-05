# A16EEN Visual Resource Library

A16EEN should reuse excellent open-source visual work instead of shipping a giant asset bundle. The project keeps the core desktop small and treats outside libraries as optional sources.

## Icons

### Lucide
https://github.com/lucide-icons/lucide

The existing A16EEN icon pipeline already uses Lucide for its own UI icons. It provides 1,600+ SVG icons and is licensed under ISC, including commercial use.

### Iconoir
https://github.com/iconoir-icons/iconoir

A strong alternative when we want a different visual voice. Iconoir provides 1,600+ SVG icons and is MIT licensed.

### Phosphor
https://github.com/phosphor-icons/core

Useful for softer, heavier, thin, duotone, and playful icon treatments. The core repository contains the raw SVG assets and catalog data and is MIT licensed.

### Material Design Icons
https://github.com/Templarian/MaterialDesign

A huge fallback library with 7,000+ community icons. Its icon assets are primarily distributed under Apache 2.0, with other files covered by their listed licenses.

## Emojis, stickers, and expressive graphics

### OpenMoji
https://github.com/hfg-gmuend/openmoji

This is one of the best sources for expressive emoji and sticker-like graphics. OpenMoji ships color and black SVG/PNG exports and is licensed CC BY-SA 4.0, so attribution and ShareAlike obligations matter when adapting the artwork.

### Twemoji
https://github.com/twitter/twemoji

A very recognizable emoji set with SVG assets. The graphics are CC BY 4.0 and require attribution; the code is MIT.

### SVGmoji
https://github.com/svgmoji/svgmoji

Useful as a unified SVG sprite approach over several popular open emoji sets. The repository itself is MIT licensed.

## Animation sources

### Lottie
https://github.com/airbnb/lottie-web

Lottie is a runtime for rendering After Effects/Bodymovin animations, not a license blanket for every animation found on the internet. The runtime itself is MIT licensed; each downloaded animation should still be checked for its own license.

### Rive
https://github.com/rive-app/rive-runtime

Excellent for interactive animated UI pieces and state-driven graphics. Rive's official runtimes are open source and MIT licensed; individual Rive assets still need their own licensing review.

A16EEN should prefer small, purpose-built animations rather than cloning entire animation repositories.

## Typography

A16EEN installs a lightweight baseline set through Arch packages:

- Inter — primary modern UI font
- Lato — softer display/secondary font
- Source Sans 3 — readable UI and text fallback
- Roboto — neutral compatibility fallback
- Roboto Mono — terminals, technical labels, diagnostics

Inter is packaged by Arch as a variable TTF/TTC family; Lato is an OFL family; Source Sans is OFL-licensed; Roboto and Roboto Mono are OFL-licensed.

### Artistic display font to keep in the toolbox: Fraunces

https://github.com/googlefonts/fraunces

Fraunces is an expressive variable display typeface with weight, optical-size, softness, and “wonky” axes. It is especially useful for editorial, cinematic, playful, or artistic A16EEN screens. The upstream font is published under the Open Font License.

We do not bundle large font files into A16EEN's core runtime. That keeps updates small while leaving the typography system open to more families later.

## Design rule for A16EEN

Do not turn these repositories into one giant asset dump.

Instead:

1. Keep a tiny built-in foundation.
2. Pin or vendor only individual assets we actually use.
3. Keep licenses/attribution beside third-party assets.
4. Let future widgets opt into larger animation or emoji libraries only when necessary.
5. Keep user-provided images outside the installed source tree so updates never erase them.
