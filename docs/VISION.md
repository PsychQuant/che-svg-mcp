# Vision

## What This Is

A native SVG manipulation server that gives AI agents a professional vector graphics workflow. Create, edit, compose, and export SVGs with the same precision you'd expect from a desktop vector editor, but driven entirely by programmatic commands.

## Design Philosophy

- **Local-first.** All operations run on your machine. No external API calls, no cloud dependencies.
- **Programmatic precision.** Every coordinate, color, and transform is explicitly specified. No AI guessing.
- **Batch-native.** Operations that would require tedious manual repetition in a GUI tool are first-class citizens here: recoloring an entire icon set, generating size variants, applying consistent styling across dozens of files.
- **Composable.** Simple primitives (shapes, paths, transforms, styles) compose into complex results. The same building blocks that create a single icon can produce an entire design system.

## What It Replaces

For many common vector graphics tasks, a desktop application is overkill:
- Creating and maintaining icon sets
- Generating logos, badges, and social cards
- Building diagrams and data visualizations
- Applying bulk style changes across SVG assets
- Exporting to multiple formats and sizes

These workflows are faster and more repeatable when driven by commands rather than mouse clicks.

## What It Does Not Replace

Complex freehand illustration, print production (CMYK, bleed, spot colors), and interactive visual design with real-time feedback still benefit from a dedicated GUI tool.

## Architecture

```
SVGDocument          ← wraps Foundation.XMLDocument
├── SVGElement       ← rect, circle, ellipse, line, polyline, polygon, path, text, image, g
├── SVGStyle         ← fill, stroke, opacity, gradient, filter, font
├── SVGTransform     ← translate, rotate, scale, skew, matrix
└── SVGExporter      ← Core Graphics → PNG, PDF
```

All manipulation happens on the XML DOM. No intermediate representation. What you edit is what gets saved.
