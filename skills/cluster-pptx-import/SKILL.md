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

### 4. Extract One Cluster At A Time

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
\SlaifMetricCard{x}{y}{w}{h}{number}{label}
\SlaifProgressBar{x}{y}{w}{value}{label}
\SlaifTableBand{x}{y}{w}{h}{fill}
\SlaifHighlightRow{x}{y}{w}{h}
\SlaifFooter{slideNumber}
```

Avoid macros that are just opaque wrappers around one instance. A useful macro
should make repeated structure easier to read and adjust.

Keep visual constants centralized when they are truly shared:

```tex
\definecolor{SlaifGreen}{HTML}{...}
\newlength{\SlaifCardRadius}
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
