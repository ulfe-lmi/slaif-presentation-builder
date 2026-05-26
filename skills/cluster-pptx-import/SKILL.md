---
name: cluster-pptx-import
description: Cluster repeated visual patterns in a raw PPTX-to-Beamer reconstruction into reusable LaTeX macros and style-file components. Use after import-pptx and refine-pptx-import have produced a visually credible raw Beamer deck, when the next goal is to identify common cards, panels, progress bars, bullets, labels, table rows, highlights, and other repeated graphical elements and migrate them into a reusable .sty template without changing rendered output.
---

# Cluster PPTX Import

## Purpose

Use this skill after a PowerPoint deck has been imported into a raw Beamer file
that already reproduces the original presentation closely enough. The goal is
to turn repeated absolute-position TikZ and Beamer fragments into reusable
LaTeX functions and style-file definitions while preserving the existing visual
result.

This is a consolidation step, not a redesign step. The raw Beamer deck is the
working baseline. The style file should emerge from observed repetition in that
file, validated against rendered output after each extraction.

## Inputs

Identify these paths before starting:

- raw Beamer source file, for example `deck.tex`
- current compiled PDF
- current Beamer-rendered PNG directory
- office-rendered reference PNG directory, if still available
- asset directory used by the Beamer deck
- target `.sty` file path, if one already exists

If the current paths are unknown, inspect the repo state, handoff notes, or
nearby durable work directories before making assumptions.

## Non-Negotiable Rules

- Do not change the visual design while clustering.
- Do not replace native TikZ shapes with raster crops.
- Do not bake normal text into images.
- Text inside logo image assets may remain part of the logo image.
- Preserve absolute visual placement unless the user explicitly asks for layout
  normalization.
- Validate after each meaningful macro extraction by recompiling and rendering.
- Compare the new render to the pre-clustering Beamer render first. Use the
  original PPTX render only as a regression guard when available.
- Keep macro names semantic enough to be reusable, but do not invent a design
  system that is not supported by repeated evidence in the deck.

## Workflow

### 1. Establish The Baseline

Compile the current raw Beamer file and render it to PNGs. Treat this render as
the clustering baseline.

Record:

- PDF path
- rendered PNG path
- slide count
- compile command
- render command
- any existing warnings that predate clustering

Do not start extracting macros until the baseline compiles.

### 2. Inventory Repeated Elements

Search the raw TeX for repeated visual primitives and local helper commands.
Useful targets include:

- cards and metric boxes
- panels and rounded rectangles
- progress bars and connected numeric labels
- table row bands and table header bands
- emphasis outlines and highlight rectangles
- bullets, ticks, icons, status markers, and pills
- footers, slide numbers, section labels, and repeated titles
- repeated image placements or clipped-image patterns
- repeated text box styles, font sizes, colors, and alignment rules

Prefer evidence from the TeX itself:

```bash
rg '\\draw|\\fill|\\node|\\placetextbox|\\includegraphics|rounded corners|line width|fill=' deck.tex
```

Group candidates by matching geometry, color, typography, and drawing order.
Repeated intent matters more than exact coordinates.

### 3. Create A Clustering Manifest

Before editing, write a small working manifest in the temporary or durable
workspace. Keep it outside the repository unless the user asks for it.

For each candidate cluster, record:

```text
cluster_id
semantic_name
slides
raw_tex_patterns
parameters_that_vary
parameters_that_are_constant
proposed_macro_name
target_location
validation_notes
```

Start with the highest-confidence clusters: elements that are repeated many
times and have simple parameter variation.

### 4. Cluster Colors First

Color clustering is the first practical clustering step. Do it before extracting
larger shape or text macros, because later macros should use semantic palette
names instead of imported generated names.

Inspect both the raw deck and the style file for color definitions and color
uses:

```bash
rg -n '^\\definecolor|fill=|draw=|\\fill\\[|\\color\\{|setbeamercolor' deck.tex path/to/style.sty
```

Cluster colors by exact RGB match first, then by near match. Near matches should
be named separately unless there is strong evidence that they are the same
semantic color. Similar RGB values can still encode different roles such as
body text, muted text, divider, card fill, panel fill, accent fill, or final
overlay stroke.

For each unique color, choose a human-readable semantic name. Use the project,
theme, or template prefix chosen for the generated style file:

```tex
\definecolor{ThemePrimary}{RGB}{20,91,110}
\definecolor{ThemeAccent}{RGB}{27,138,167}
\definecolor{ThemeInk}{RGB}{28,43,51}
\definecolor{ThemeMutedText}{RGB}{85,102,112}
\definecolor{ThemeSuccess}{RGB}{143,188,47}
\definecolor{ThemeBorder}{RGB}{216,224,228}
\definecolor{ThemeSurface}{RGB}{242,246,248}
\definecolor{ThemeWhite}{RGB}{255,255,255}
```

Use names that describe how the color is used, not just how it looks. Prefer
`ThemeSurface`, `ThemeBorder`, `ThemeMutedText`, and `ThemeSuccessDark` over names
that only encode a hue.

After defining semantic colors in the `.sty` file:

1. Replace generated color names in the deck with semantic names.
2. Replace duplicate aliases with a single semantic name.
3. Replace literal `white` with the semantic white color when consistency helps.
4. Remove generated color definitions only after no deck or style references
   remain.
5. Run a strict scan for remaining unnamed colors.
6. Compile, render, and compare against the pre-color-clustering Beamer render.

The strict scan should report only semantic palette names and non-color tokens
such as `none`:

```python
from pathlib import Path
import re

paths = [Path("deck.tex"), Path("path/to/generated-theme.sty")]
theme_prefix = "Theme"
issues = []

for path in paths:
    for i, line in enumerate(path.read_text().splitlines(), 1):
        for kind, value in re.findall(r"(?<![A-Za-z])(fill|draw|color|text|bg)=([^,}\\]]+)", line):
            if value != "none" and not value.startswith(theme_prefix):
                issues.append((path, i, kind, value))
        for value in re.findall(r"\\fill\[([^\]]+)\]", line):
            if not value.startswith(theme_prefix):
                issues.append((path, i, "fill[]", value))
        for value in re.findall(r"\\definecolor\{([^}]+)\}", line):
            if not value.startswith(theme_prefix):
                issues.append((path, i, "definecolor", value))

print(issues)
```

The color-clustering step is complete only when:

- all active color definitions in the style file use semantic names
- the deck uses semantic palette names instead of generated import names
- literal color names have been eliminated or deliberately justified
- compilation succeeds
- rendered output is unchanged from the pre-color-clustering Beamer baseline

### 5. Extract Title And Cover Slide Templates

Title and cover slides are good early template candidates because the visual
layout is usually fixed while the content fields are few and semantically clear.
Move all fixed geometry, images, overlays, text-box coordinates, font sizes,
and colors into the generated `.sty` file. The deck should contain only
content fields.

Prefer key-value fields instead of positional arguments. Positional arguments
become unreadable as soon as there are more than two or three fields.

Good deck-side shape:

```tex
\ThemeTitleSlide{
  title       = {Project Title},
  author      = {Presenter Name},
  institution = {Institution Name},
  role        = {Presenter Role},
  event       = {Review Meeting},
  subtitle    = {Months 1--7 Progress},
  date        = {2026-05-26}
}
```

Use field names that describe the content, not the source slide's internal
textbox number. Typical title-slide fields:

- `title`
- `subtitle`
- `author`
- `institution`
- `role`
- `event`
- `date`

Do not require every field. Title-slide composers must handle empty fields
without leaving dangling separators. If a metadata line joins
`author`, `institution`, and `role`, print delimiters only between fields that
are actually present. If an event line joins `event` and `subtitle`, omit the
separator when either side is empty.

In LaTeX, implement this as a small key family and a helper that appends
non-empty fields:

```tex
\pgfkeys{
  /ThemeTitleSlide/.is family,
  /ThemeTitleSlide,
  title/.store in=\ThemeTitleTitle,
  author/.store in=\ThemeTitleAuthor,
  institution/.store in=\ThemeTitleInstitution,
  role/.store in=\ThemeTitleRole,
  event/.store in=\ThemeTitleEvent,
  subtitle/.store in=\ThemeTitleSubtitle,
  date/.store in=\ThemeTitleDate,
}
```

The exact implementation can vary, but the behavior must be:

- empty fields are allowed
- delimiters are conditional
- fixed visual assets and geometry stay in the `.sty`
- deck-side title-slide code contains content only
- the extracted title slide renders identically to the raw Beamer baseline

Validate title-template extraction with two checks:

1. Recompile and pixel-compare the extracted title slide against the previous
   Beamer render.
2. Compile a temporary smoke-test title slide with some empty fields and inspect
   text extraction or the render to confirm no dangling delimiters appear.

### 6. Extract One Cluster At A Time

For each cluster:

1. Define the macro in the `.sty` file or a temporary style section.
2. Replace only the matching raw snippets in `deck.tex`.
3. Keep the output visually identical.
4. Recompile and rerender.
5. Compare against the pre-extraction Beamer render.
6. Fix regressions before extracting another cluster.

Do not perform a large mechanical rewrite across many element types in one
step. Small verified extractions make visual regressions easier to isolate.

## Macro Design

Macros should expose the parameters that actually vary across the deck.

Good candidates:

```tex
\ThemeMetricCard{x}{y}{w}{h}{number}{label}
\ThemeProgressBar{x}{y}{w}{value}{label}
\ThemeTableBand{x}{y}{w}{h}{fill}
\ThemeHighlightRow{x}{y}{w}{h}
\ThemeFooter{slideNumber}
```

Avoid macros that are just opaque wrappers around one instance. A useful macro
should make repeated structure easier to read and adjust.

Keep visual constants centralized when they are truly shared:

```tex
\definecolor{ThemeSuccess}{HTML}{...}
\newlength{\ThemeCardRadius}
```

Do not centralize values that only look similar by coincidence.

## Drawing Order

Preserve drawing order exactly unless the current order is known to be wrong.
Some elements must be deliberately late overlays:

- emphasis outlines
- row highlights
- selection rectangles
- annotation borders
- any stroke that must remain visible above bands, panels, or table rows

When creating macros for these elements, document whether they are background,
content, or final-overlay primitives. Final-overlay primitives should be emitted
after the content they emphasize.

## Validation

After each extraction:

- compile the Beamer deck
- render the PDF to PNG at the same resolution as the baseline
- compare the affected slides against the pre-clustering Beamer PNGs
- inspect crops of any affected repeated element at original size
- confirm no text moved, disappeared, overlapped, or changed size

Use image differences as a locator, not as the only judge. A small antialiasing
difference may be acceptable; shifted geometry, changed typography, or hidden
strokes are not.

## Expected Outputs

The clustering phase should produce, when requested:

- an updated `.sty` file containing reusable visual primitives
- a simpler `deck.tex` that calls those primitives
- a clustering manifest or notes describing extracted element families
- rendered verification PNGs
- a compiled PDF
- a short list of unresolved clusters that should remain raw for now

## Stop Conditions

Stop and ask before proceeding when:

- the raw Beamer baseline does not compile
- required fonts or tools are missing
- a proposed macro changes the rendered output in a way that cannot be explained
- two visually similar elements have conflicting semantics and should not share
  a macro without user approval
- the user asks to preserve the raw deck exactly and only produce a clustering
  proposal
