---
name: create-presentation
description: Create a Beamer presentation from an imported markdown content dossier, extracted assets, source documents, or a user outline by reusing the repository's presentation template, compiling locally, inspecting rendered output, and iterating until the PDF is usable. Use after import-source-material or when the user directly asks to build slides from source content.
---

# Create A Beamer Presentation From Imported Material

## Purpose

Use this skill to build an actual Beamer presentation from source material,
usually after an `import-source-material` workflow has produced a `contents.md`
handoff and extracted assets.

This skill covers:

- selecting the appropriate repository template
- converting a markdown content dossier or user outline into slides
- inserting extracted assets, figures, tables, equations, and crops
- compiling the Beamer deck
- inspecting the rendered PDF
- fixing layout, overflow, cropping, and readability issues

## Non-Negotiable Rules

- Reuse the repository's presentation template or requested template.
- Preserve template-like code unless the user explicitly asks to alter it.
- Keep content edits separate from reusable style/framework edits.
- If the requested slide change cannot be expressed with existing template
  elements, stop before editing and tell the user exactly what is missing.
  Request explicit confirmation or a design decision before either
  adding/extending reusable template elements in the style file or introducing
  any custom presentation-side element.
- Never silently choose between changing the template and adding custom
  deck-side visual code. The user must approve that direction first.
- For SLAIF decks, `deck.tex` is content only and `slaif.sty` is the
  presentation system. Never define new visual elements, helper drawing macros,
  local card/note/image/bar helpers, colors, layout primitives, or repeated
  geometry in `deck.tex`.
- If a slide needs a visual element that is not already available, first add or
  extend the reusable macro in `slaif.sty`, then use that macro from `deck.tex`.
  This applies to cards, panels, notes, footnotes, figures, image placement,
  bullet lists, bar/slider charts, timelines, tables, arrows, badges, dividers,
  and any other repeated visual structure.
- Do not use footnote panels as general content containers. Footnote panels are
  for citations, source notes, and references only.
- Do not force ordinary bullet lists into panels or small-text panel groups when
  the slide needs bullets directly under, beside, or between other elements. Use
  the template's existing green or blue bullet-list macros directly in the slide
  body.
- Before adding a new bullet-list macro, check whether the template already has
  an appropriate bullet-list macro and reuse it.
- Do not solve layout problems by adding ad hoc `\newcommand`,
  `\placetextbox`, `\drawshape`, raw TikZ, or direct `\includegraphics` calls
  in `deck.tex`. Existing template macros may use those primitives internally;
  slide content must not.
- Compile the deck locally before calling the task done.
- Render or inspect the PDF output, not just the TeX source.
- Iterate until the presentation compiles and visible layout problems are fixed.
- Do not push or commit generated PDFs/build artifacts unless explicitly asked.
- If required fonts, LaTeX packages, or asset files are missing, report that
  clearly and do not pretend the rendered output is validated.

## Inputs

Start by locating one or more of:

- imported `contents.md`
- temporary import workspace
- extracted asset directory
- source PDFs/DOCX/LaTeX/images
- user outline or slide plan
- target template directory
- existing Beamer deck to modify

If no imported dossier exists, use the source material directly, but create a
brief internal outline before writing slides.

## Workflow

### 1. Establish The Build Target

Identify:

- target `.tex` file to create or edit
- style file or template directory
- asset directory
- build directory
- compile command
- intended output PDF path

Prefer a durable repository path for the final deck and a local build directory
for generated artifacts.

### 2. Read The Content Dossier

When `contents.md` exists, use it as the main source of truth:

- source inventory
- proposed presentation structure
- slide candidate map
- extracted assets
- open questions

Keep source traceability available while writing slides. If a content point is
unclear, return to the original source file or extracted text instead of
guessing.

### 3. Create The Slide Plan

Before editing many slides, decide:

- title/opening slides
- section/divider slides
- content slide sequence
- visual-heavy slides
- table/equation slides
- appendix or backup slides

Keep slide density reasonable. Split overloaded content into multiple slides.
Use the template's existing macros and slide types before adding new ones.

### 4. Write The Beamer Source

Use the repository's established macro style. Prefer semantic slide macros
where available, such as title, divider, plain, panel, table, slider, timeline,
or final-slide macros.

For SLAIF presentations:

- use `slaif.sty` as the only place for template behavior and visual
  primitives
- keep `deck.tex` limited to slide order, text, data values, asset filenames,
  and calls to `slaif.sty` macros
- before writing or editing a slide, search `slaif.sty` for an existing macro
  that already expresses the needed visual pattern
- if no suitable macro exists, extend `slaif.sty` with a semantic, reusable
  macro and then call it from `deck.tex`
- avoid one-off local helpers even when they seem faster; one-off helpers are
  template changes and belong in `slaif.sty`
- keep content semantics intact: citations belong in footnotes, while ordinary
  bullets should remain ordinary bullets instead of being hidden inside another
  visual component

When inserting source assets:

- use relative paths from the TeX file when the asset is repository-local
- preserve image aspect ratio unless a template macro intentionally clips it
- use readable crop sizes
- avoid full-page screenshots when a focused crop is better
- keep captions and labels concise

For text:

- condense long paragraphs into slide-appropriate bullets
- preserve technical meaning
- keep terminology consistent with the source
- keep equations and symbols exact
- do not silently add unsupported claims

### 5. Compile

Use the engine required by the template. For XeLaTeX-based decks:

```bash
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=build deck.tex
```

If compilation fails:

1. read the actual LaTeX error
2. patch the root cause
3. recompile
4. repeat until successful

Install missing packages only when permitted by the current environment and
user instructions. Otherwise report exactly what is missing.

### 6. Render And Inspect

Render the compiled PDF to images for visual checks:

```bash
pdftoppm -png -scale-to 1920 build/deck.pdf build/rendered/slide
```

Inspect all slides for:

- text outside the frame
- title/body overlap
- unreadably small text
- badly cropped images
- figures or tables crossing boundaries
- broken bullets
- inconsistent footer/header behavior
- obvious alignment problems
- missing fonts or substituted glyphs

Also inspect the TeX source for template-boundary violations before finishing:

```bash
rg -n '\\newcommand|\\placetextbox|\\drawshape|\\begin\{tikzpicture\}|\\includegraphics' deck.tex
```

If this finds newly introduced local visual primitives or raw layout code in
`deck.tex`, move that behavior into `slaif.sty` and replace the deck-side code
with semantic macro calls before reporting the work as done. Existing raw
fragments from older imported decks should be treated as technical debt and not
copied or expanded.

For details, crop the suspect region and inspect it directly.

### 7. Iterate

Fix visible problems and recompile. Common fixes:

- split dense slides
- shorten bullets
- move material into two columns
- resize or recrop visuals
- adjust macro parameters
- use a more appropriate template slide type
- move secondary detail to appendix slides

Do not stop at "compiles" if the PDF is visibly flawed.

## Output Report

When done, report:

- final TeX path
- final PDF path
- compile command used
- any assets created or moved
- any unresolved layout/content risks

Keep the report concise, but include enough detail for the user to open the PDF
and continue reviewing.
