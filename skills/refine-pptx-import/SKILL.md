---
name: refine-pptx-import
description: Continue and refine an already-imported PPTX-to-Beamer reconstruction by comparing Beamer-rendered PNGs to office-rendered PPTX reference slides, preserving editable native Beamer/TikZ output, and applying visual fixes without baking rendered text into assets. Use after an import-pptx workflow has produced reference renders, extracted media, a generated Beamer deck, or a partially refined Beamer reconstruction.
---

# Refine PPTX Import

## Purpose

Use this skill after an initial PPTX import has already produced a Beamer deck
or partial Beamer reconstruction. The goal is to iteratively improve the
Beamer-rendered slides until they are visually credible against the
office-rendered PPTX reference, while keeping the output editable and
reproducible.

Use the initial import skill for:

- rendering the PPTX with an office application
- extracting PPTX media and geometry
- creating asset and structure manifests
- generating the first Beamer deck

Use this refinement skill for:

- rerendering reference and Beamer outputs
- inspecting slide-by-slide visual regressions
- patching Beamer geometry, text boxes, opacity, cards, bullets, progress bars,
  and footers
- keeping normal text live and simple shapes native
- recording residual issues clearly

## Non-Negotiable Rules

- Do not use cropped rendered text as a final solution.
- Do not use rendered card, panel, table, metric, or progress-bar crops as final
  assets.
- Cards, metric boxes, panels, table bands, row highlights, pills, bullets,
  dividers, progress bars, and simple shapes must be native TikZ/Beamer.
- Emphasis outlines and highlight rectangles must be drawn last as final
  overlays, even when current ordering appears visually harmless.
- Normal slide text must be live Beamer text.
- Text that is part of a logo image may remain inside that logo image.
- Use an existing completed showroom template as the reference for the
  `.tex`/`.sty` boundary. For the SLAIF template, inspect
  `templates/slaif/slaif.tex` and `templates/slaif/slaif.sty`: deck `.tex`
  should contain slide order, content, data, asset filenames, and semantic
  macro calls; reusable geometry, colors, typography, drawing primitives,
  repeated layout logic, and component definitions belong in `.sty`.
- During refinement, do not add new repeated raw textbox/drawing code to the
  `.tex` file when the issue is really a missing or incomplete reusable
  component. Extend the style/template layer and then call the semantic macro
  from the deck.
- Use the office-rendered PPTX slides as the visual reference, but also judge
  final Beamer slide quality directly.
- Avoid blindly optimizing pixel-diff metrics at the expense of readable,
  editable Beamer output.
- Do not rely on `/tmp` for multi-turn refinement. Use a durable workspace.
- Do not commit generated reconstruction files unless explicitly requested.

## State Discovery

Do not hardcode paths or assume the previous temporary workspace still exists.
At the start of a refinement turn, identify:

- source PPTX path
- durable work directory
- reference PNG directory
- Beamer source path
- Beamer PDF path
- Beamer-rendered PNG directory
- extracted media directory
- current manual patches already applied

If the repo has a `state.txt` or prior handoff file, read it before continuing.
If a path mentioned in prior work no longer exists, rebuild into a durable
workspace instead of pretending it is still valid.

Use placeholders like these in commands and notes:

```text
WORK=/durable/workspace/path
SOURCE_PPTX=/path/to/source.pptx
BEAMER_TEX=$WORK/beamer/deck.tex
REFERENCE_PNG_DIR=$WORK/reference/png
BEAMER_PNG_DIR=$WORK/beamer/rendered
```

## Rebuild Commands

### Render PPTX Reference

Render through an installed office application. Use an isolated profile when
running headless office tools so repeated conversions are deterministic and do
not depend on a user session.

```bash
mkdir -p "$WORK"/{source,reference/pdf,reference/png,extracted-media,beamer/assets,beamer/build,beamer/rendered,beamer/checks,analysis}
cp "$SOURCE_PPTX" "$WORK/source/source.pptx"

profile="$WORK/office-profile"
mkdir -p "$profile"

libreoffice \
  --headless \
  --nologo \
  --nofirststartwizard \
  --nodefault \
  --nolockcheck \
  --norestore \
  "-env:UserInstallation=file://$profile" \
  --convert-to pdf \
  --outdir "$WORK/reference/pdf" \
  "$WORK/source/source.pptx"
```

Render reference PNGs with the long edge fixed to `1920` while preserving aspect
ratio:

```bash
pdftoppm \
  -png \
  -scale-to 1920 \
  "$WORK/reference/pdf/source.pdf" \
  "$WORK/reference/png/page"
```

Normalize names:

```python
from pathlib import Path

p = Path("$WORK/reference/png")
for f in sorted(p.glob("page-*.png")):
    n = int(f.stem.split("-")[-1])
    f.rename(p / f"slide-{n:02d}.png")
```

Why `-scale-to 1920`: DPI-based rasterization can produce off-by-one dimensions
when the PDF page has fractional point dimensions. `-scale-to 1920` preserves
aspect ratio and avoids accidental size drift.

### Compile Beamer

Use XeLaTeX unless the project explicitly uses a different engine:

```bash
latexmk \
  -cd \
  -xelatex \
  -interaction=nonstopmode \
  -halt-on-error \
  -outdir="$WORK/beamer/build" \
  "$WORK/beamer/deck.tex"
```

### Render Beamer Checks

```bash
rm -rf "$WORK/beamer/rendered"
mkdir -p "$WORK/beamer/rendered"

pdftoppm \
  -png \
  -scale-to 1920 \
  "$WORK/beamer/build/deck.pdf" \
  "$WORK/beamer/rendered/page"
```

Normalize names:

```python
from pathlib import Path

p = Path("$WORK/beamer/rendered")
for f in sorted(p.glob("page-*.png")):
    n = int(f.stem.split("-")[-1])
    f.rename(p / f"slide-{n:02d}.png")
```

## Core Refinement Loop

For each targeted slide:

1. Open the Beamer-rendered slide PNG.
2. Open the matching office-rendered PPTX reference PNG.
3. Inspect the visible problem directly.
4. Patch only the affected slide unless the user asks for a global rule.
5. Compile with XeLaTeX.
6. Render the Beamer PDF to PNG at `-scale-to 1920`.
7. Reopen the edited slide.
8. Compare against the reference to prevent drift.
9. Record what changed and any remaining risk.

Common regressions to look for:

- missing shapes
- accidental large grouped artifacts
- wrong opacity
- text overlap
- text floating above or below a bar/card
- footer/date color or placement mismatch
- card text too close to numbers
- native card geometry mismatch
- missing rounded highlight rectangles
- incorrect aspect ratio for grouped images

## Visual Inspection Rules

### Use Metrics Only As A Guide

Pixel-diff metrics can help find suspect slides, but they are not success or
failure thresholds. Text antialiasing, font substitution, and line breaking can
keep metrics nonzero even when a slide is acceptable.

Always inspect the rendered image.

### Crop First When The User Points At A Detail

When the user provides a crop or says "look at it", do not infer the target
object from nearby discussion. Open the crop at original size and identify the
actual object first.

Procedure:

1. Open the user-provided crop at original size.
2. Identify visible color, local context, neighboring shapes, and likely slide
   region.
3. Locate the matching object in the current Beamer render and PPTX reference
   render.
4. Crop the same region from both renders and inspect them side by side.
5. Only then locate the corresponding TeX line.
6. If a previous edit targeted the wrong object, revert it before applying the
   correct fix.

This matters especially when multiple slides contain similar numbers, bars,
cards, or repeated labels.

### Generate Variant Sheets For Fragile Alignment

For small placement issues, generate a rendered variant sheet before choosing a
fix. Do not rely on box coordinates alone.

```python
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

work = Path("$WORK")
deck = work / "beamer/deck.tex"
orig = deck.read_text()

old = r"\placetextbox{...}{...}{...}{...}{...}{...}{...}{...}"
variants = [
    ("current", old),
    ("lower 1", r"\placetextbox{...}{...}{...}{...}{...}{...}{...}{...}"),
    ("lower 2", r"\placetextbox{...}{...}{...}{...}{...}{...}{...}{...}"),
]

slide_number = 1
box = (0, 0, 400, 200)  # full-resolution PNG crop box
outdir = work / "beamer/checks/variants"
outdir.mkdir(parents=True, exist_ok=True)

images = []
ref = Image.open(work / f"reference/png/slide-{slide_number:02d}.png").convert("RGB").crop(box)
ref = ref.resize(((box[2] - box[0]) * 3, (box[3] - box[1]) * 3))
canvas = Image.new("RGB", (ref.width, ref.height + 34), "white")
canvas.paste(ref, (0, 34))
ImageDraw.Draw(canvas).text((8, 8), "PPTX reference", fill=(0, 0, 0))
images.append(canvas)

try:
    for name, line in variants:
        deck.write_text(orig.replace(old, line))
        subprocess.run(
            [
                "latexmk",
                "-cd",
                "-xelatex",
                "-interaction=nonstopmode",
                "-halt-on-error",
                f"-outdir={work}/beamer/build",
                str(deck),
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.STDOUT,
            check=True,
        )
        subprocess.run(
            [
                "pdftoppm",
                "-png",
                "-f",
                str(slide_number),
                "-singlefile",
                "-scale-to",
                "1920",
                str(work / "beamer/build/deck.pdf"),
                str(outdir / "tmp"),
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        im = Image.open(outdir / "tmp.png").convert("RGB").crop(box)
        im = im.resize(((box[2] - box[0]) * 3, (box[3] - box[1]) * 3))
        canvas = Image.new("RGB", (im.width, im.height + 34), "white")
        canvas.paste(im, (0, 34))
        ImageDraw.Draw(canvas).text((8, 8), name, fill=(0, 0, 0))
        images.append(canvas)
finally:
    deck.write_text(orig)
```

## Important Lessons

### Reference Rendering Must Be Office-Based

Render the source PPTX through an installed office application first. Do not use
screenshots as the primary reference when a headless office path is available.

### Long Edge Must Be 1920px With Preserved Aspect Ratio

Use `pdftoppm -png -scale-to 1920`. Do not use arbitrary DPI or force both
width and height independently.

### Text Is Native Except Logo Text

Normal slide text must remain live Beamer text. Logo-internal text may remain
inside the logo image because it belongs to the logo asset.

### Match Text Using PPTX Runs And Rendered Bands

When text size looks wrong, inspect the source PPTX text runs before guessing.
Use `python-pptx` to read each text shape, paragraph, run font size, bold/italic
state, text box geometry, and text-frame margins. If the system `python3` lacks
`python-pptx`, check the repository virtual environment before installing
anything.

PPTX font sizes should usually become the Beamer `\fontsize` values for the
corresponding live text. However, matching only the numeric font size is not
enough. PowerPoint text boxes often have internal margins and baseline behavior
that make text render several points away from the raw shape origin. After
applying source run sizes, compare rendered glyph bands between the office
reference PNG and Beamer PNG:

- line bounding-box height confirms whether font size is correct
- line bounding-box `x` and `y` reveal missing text-frame margin offsets
- line spacing may need a Beamer line-height adjustment even when font size is
  correct
- separate PPTX runs or paragraphs with different sizes/styles should be
  represented as separate live Beamer text boxes or explicit styled lines when
  needed for accurate matching

Preserve run-level emphasis. Do not force an entire text block to be bold,
italic, or otherwise emphasized just because the imported reconstruction did.
Compare the source render and PPTX runs, then apply emphasis only to the
sentences, phrases, or runs that are actually emphasized.

Do not compensate for a placement or text-margin mismatch by changing font size.
First make the rendered glyph heights match the reference, then tune text-box
position, paragraph width, and line spacing.

### Cards And Panels Must Be TikZ

Use native TikZ for:

- rounded metric cards
- table/card containers
- section panels
- course-description panels
- timeline cards
- row bands
- KPI highlight boxes
- progress bars

Rendered crops create uneditable output and often include baked text or masking
artifacts.

### Grouped Shapes Can Mislead The Generator

Presentation generators may expose grouped bullets, labels, or nested layouts
as standalone shapes. Drawing those literally can produce large accidental
ellipses, missing text, or distorted grouped images.

Correct approach:

- inspect grouped shapes recursively
- ignore generated group artifacts that do not match the render
- reconstruct simple bullets, labels, and containers natively
- place true image assets only where the source actually uses image content

### PPTX Opacity Must Be Read From OOXML

If a raster asset renders too opaque, inspect the raw OOXML for opacity
modifiers such as `alphaModFix`. Convert `amt` values to opacity by dividing by
`100000`.

Use an opacity-aware image macro when needed:

```tex
\newcommand{\placeimageopacity}[6]{%
  \begin{tikzpicture}[remember picture,overlay]
    \node[anchor=north west,inner sep=0pt,opacity=#6]
      at ([xshift=#1bp,yshift=-#2bp]current page.north west)
      {\includegraphics[width=#3bp,height=#4bp]{assets/#5}};
  \end{tikzpicture}%
}
```

### Footer Treatment Must Be Consistent

Use a consistent footer baseline, color, and alignment for repeated footer
elements. Do not assume every slide has identical footer contents; title,
closing, and section slides may intentionally omit or replace some footer
fields.

### Section Header Spacing Needs Visual Tuning

If a small section label touches a large title, reduce and reposition the small
label before moving the large title. Moving the main title often creates more
drift than fixing the small label.

### Progress-Bar Numbers Need Rendered Baseline Checks

For progress bars, the PPTX and TeX text-box geometry can be correct while the
glyph itself renders too high or too low. Judge the rendered digit relative to
the fill bar and pale background bar.

Fix order:

1. Identify the exact number from a crop or side-by-side render.
2. Revert any previous change to a wrong matching number.
3. Tune the text-box `y` position.
4. Avoid horizontal scaling unless a rendered variant proves it improves the
   match.

When a slide contains several repeated progress bars, treat the bar labels as a
set. If one row has a baseline or vertical-centering defect, inspect every
sibling row on the same slide before declaring the fix complete. A single
accepted row does not prove the other rows are aligned, because numeric glyphs,
bar heights, and row spacing can differ enough for each label to need its own
small adjustment.

For repeated progress-bar sets:

1. Crop the full group of bars from the reference and Beamer render.
2. Make a side-by-side sheet that includes every row, not only the row first
   reported as wrong.
3. Check each number against its own fill bar and background bar.
4. Apply row-specific `y` adjustments where needed.
5. Re-render and inspect the full group again so a fix for one row does not
   hide regressions in neighboring rows.

### Line-Only Shapes May Need Manual Native Reconstruction

Line-only rounded rectangles, row highlights, and outlines may have no fill and
implicit line color. If extraction misses them, add explicit native TikZ
outline rectangles with measured coordinates.

Draw emphasis outlines and highlight rectangles last, as final overlays. This is
mandatory even if a particular render appears correct with earlier draw order.
Later row bands, fills, image masks, or grouped shapes can cover one edge of a
rounded rectangle, and the defect may only appear after later refinements. For
table row emphasis, draw the table backgrounds and text first, then draw all
emphasis rectangles at the end of the slide or at least after every neighboring
row background that could overlap them.

## Editing Guidance

Use `apply_patch` for manual TeX/source edits.

Do not regenerate `deck.tex` from the import generator after manual patches
unless you first preserve or reapply manual refinements. The generator is a
starting point, not the source of truth after refinement begins.

Keep a handoff list of manual patches. Typical entries include:

- opacity-aware image macro
- native bullet replacements
- native card or panel reconstruction
- progress-bar label vertical adjustment
- row highlight outlines
- grouped-image aspect-ratio correction
- footer convention adjustments

## Common Failure Modes And Fixes

### Huge Ellipses Where Bullets Should Be

Cause:

- grouped bullet/text shapes were interpreted as standalone ellipses.

Fix:

- remove large ellipse draw commands
- add native small bullet circles
- add live text boxes beside bullets

### Logo Text Is Mistaken For Baked Slide Text

Cause:

- a logo contains text.

Fix:

- allow logo text to remain inside the logo image
- do not crop arbitrary slide text

### Faint Image Renders Too Bold

Cause:

- OOXML opacity was ignored.

Fix:

- inspect raw OOXML
- use an opacity-aware image macro

### Header Part Label Touches Title

Cause:

- Beamer font metrics made the smaller label too tall or too close to the main
  title.

Fix:

- reduce and lower the small label
- avoid moving the main title too far down

### Missing Row Highlights

Cause:

- line-only rounded rectangles may have missing or implicit line color.
- highlight outlines may be drawn before later backgrounds, so one side of the
  rectangle is covered.

Fix:

- draw explicit native rounded outline rectangles with measured coordinates.
- draw highlight and emphasis outlines last as final overlays.

### Footer Color Inconsistency

Cause:

- raw placeholders may render in different colors depending on source layout.

Fix:

- set footer text color explicitly for each repeated footer element.

### Small Progress-Bar Number Floats Above The Bar

Cause:

- text-box geometry matches the source, but XeLaTeX places the glyph too high
  inside the box
- the wrong repeated number may have been edited if the crop was not inspected
  first
- only one row in a repeated progress-bar set was checked, leaving sibling rows
  with the same visual defect

Fix:

- inspect the crop and identify the exact bar/color/row
- make side-by-side crops from the PPTX reference and Beamer render
- when the slide has repeated bars, crop and inspect the entire set
- tune the text-box `y` position using rendered variants
- avoid arbitrary horizontal scaling as a first fix

## Completion Criteria

A refinement pass is complete only when:

- `deck.tex` compiles with XeLaTeX
- all Beamer PNGs render at the expected dimensions
- each edited slide has been visually inspected
- no edited slide has obvious text overlap, invisible text, missing shape, or
  accidental group artifact
- dense slides have readable line breaks
- repeated footer placement/color is consistent
- deviations from the PPTX reference are intentional and documented
- no rendered text crops are used as final assets

## Handoff Summary Template

When pausing refinement, record:

```text
WORK=
SOURCE_PPTX=
REFERENCE_PNG_DIR=
BEAMER_TEX=
BEAMER_PDF=
BEAMER_PNG_DIR=
EXTRACTED_MEDIA_DIR=

Manual patches:
- ...

Verified slides:
- ...

Remaining checks:
- ...
```
