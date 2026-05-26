---
name: import-pptx
description: Reconstruct a PowerPoint deck into a Beamer-compatible asset and layout system by rendering through LibreOffice, extracting PPTX media with python-pptx, refining reusable assets, documenting slide structure, generating absolute-position Beamer, and validating against rendered reference slides. Use when importing an existing PPTX/POTX/PPT template or deck into a reproducible Beamer workflow.
---

# Import PPTX Into A Reproducible Beamer Workflow

## Purpose

Use this skill to import an existing PowerPoint presentation or template into a
reproducible Beamer workflow. The objective is not to hand-design a new theme.
The objective is to inspect the original PPTX, render it through the same kind
of office pipeline a user would see, extract and classify assets, reconstruct
slide structure, generate absolute-position Beamer frames, and compare the
Beamer output against the office-rendered reference slides.

This workflow favors evidence over assumption:

- Render the PPTX with LibreOffice first.
- Treat rendered slides as visual ground truth.
- Use `python-pptx` as the primary PPTX API.
- Use OOXML only for details that `python-pptx` exposes through shape elements
  but does not model directly, such as `a:srcRect`, image effects, shape fills,
  and relationship ids.
- Keep all exploratory outputs in a system temporary directory until the user
  explicitly asks to add files to the repository.

## Non-Negotiable Rules

- Do not create a Beamer reconstruction before rendering the PPTX through
  LibreOffice and extracting a reference PNG set.
- Do not use screenshots from a GUI as the reference unless headless office
  rendering is unavailable.
- Do not treat PowerPoint image crop metadata (`a:srcRect`) as a reason to bake
  text or overlays into an image asset. It is placement metadata and can usually
  be reproduced in Beamer by clipping or pre-cropping the original image.
- Do not classify an image as manipulated merely because it has text over it.
  Text is reproducible in Beamer and should remain live text.
- Do not classify an image as manipulated merely because simple rectangles,
  rules, rounded rectangles, pills, badges, table bands, bars, or ellipses are
  placed over it. These should be reproduced separately from the image.
- Card-like UI containers must be reconstructed as native Beamer/TikZ shapes,
  not as rendered slide crops. This includes cards, panels, rounded rectangles,
  metric/stat boxes, status pills, table row bands, header bands, progress bars,
  callout boxes, and dividers. Their text must remain live Beamer text.
- Do not use cropped rendered text as an admissible final Beamer solution.
  Rendered text crops may be used only as a validation experiment to isolate
  geometry/asset problems from font/text-layout problems.
- Do not commit temporary analysis outputs unless explicitly instructed.

## Required Tools

Confirm these before starting:

- `python3` with `python-pptx`, `lxml`, `Pillow`, `numpy`
- LibreOffice or `soffice`
- Poppler tools: `pdfinfo`, `pdftoppm`
- Image inspection/comparison tools: ImageMagick or Python/Pillow
- LaTeX tooling: `xelatex`, `latexmk`
- Required template fonts installed locally

Font availability matters. If the PPTX uses a font such as Roboto Condensed,
verify it with:

```bash
fc-match "Roboto Condensed"
fc-match "Roboto"
```

If the wrong font is returned, stop and ask for the required template fonts or
install an available system package when permitted. Do not chase visual
alignment errors while LaTeX is substituting fonts.

## Output Discipline

For exploratory import work, use a dedicated temporary root:

```bash
workdir="$(mktemp -d /tmp/pptx-import-XXXXXX)"
```

Keep intermediate paths explicit:

```text
$workdir/source/
$workdir/reference/
$workdir/reference/png/
$workdir/extracted-media/
$workdir/refined/
$workdir/refined/assets/
$workdir/beamer/
$workdir/beamer/assets/
$workdir/beamer/rendered/
$workdir/beamer/diff/
```

Only write into the repository when the user asks for durable artifacts.

## Phase 1: Render The PPTX Through Office

Copy the PPTX into the temporary work directory and render with LibreOffice to
PDF. Use an isolated LibreOffice profile to avoid lock files or user profile
state:

```bash
tmpdir="$(mktemp -d /tmp/pptx-render-XXXXXX)"
cp path/to/source.pptx "$tmpdir/source.pptx"
lo_profile="$tmpdir/lo-profile"
mkdir -p "$lo_profile"

libreoffice \
  --headless \
  --nologo \
  --nofirststartwizard \
  --nodefault \
  --nolockcheck \
  --norestore \
  "-env:UserInstallation=file://$lo_profile" \
  --convert-to pdf \
  --outdir "$tmpdir" \
  "$tmpdir/source.pptx"
```

Then render the PDF to PNG using the intended longest slide dimension. For a
standard 16:9 deck, use a 1920 px long edge:

```bash
mkdir -p "$tmpdir/png"
pdftoppm -png -scale-to 1920 "$tmpdir/source.pdf" "$tmpdir/png/slide"
```

Prefer `-scale-to 1920` over a guessed DPI. DPI can produce off-by-one output
sizes when the PDF page is, for example, `960.009 x 540 pt`. `-scale-to 1920`
preserves the aspect ratio and fixes the long edge exactly.

Validate:

```bash
pdfinfo "$tmpdir/source.pdf" | rg 'Pages|Page size'
find "$tmpdir/png" -name 'slide-*.png' | sort | wc -l
identify "$tmpdir/png/slide-01.png"
```

Expected result for a 16:9 deck is usually `1920x1080`, but always derive this
from the rendered PDF/page aspect ratio.

## Phase 2: Extract All PPTX Media With python-pptx

Use `python-pptx` as the primary API. Extract all `/ppt/media/*` package parts:

```python
from pathlib import Path
from pptx import Presentation

prs = Presentation("source.pptx")
media_dir = Path("/tmp/pptx-import/extracted-media")
media_dir.mkdir(parents=True, exist_ok=True)

part_to_file = {}
for part in prs.part.package.iter_parts():
    partname = str(part.partname)
    if partname.startswith("/ppt/media/"):
        out = media_dir / Path(partname).name
        out.write_bytes(part.blob)
        part_to_file[partname] = out
```

Include SVG, PNG, JPEG, and any other media part. Do not assume that all visual
assets appear directly in slide XML; many appear through slide layouts and
masters.

## Phase 3: Build Initial Asset Usage Map

Create an `assets.tsv`-style table with two rows per rendered slide:

```text
slide_png    usage          extracted_images
slide-01.png direct         comma,separated,assets
slide-01.png manipulated    comma,separated,assets
```

Traverse, in visual inheritance order:

1. Slide master shapes
2. Slide layout shapes
3. Slide shapes

For each slide, gather images from:

- `shape._element.xpath(".//a:blip")`
- background image fills under `p:cSld/p:bg`
- the relationship id on `r:embed` / `r:link`
- the correct owning part, e.g. `shape.part.related_part(rId)`

Classification:

- `direct`: original image can be reused as an asset with placement/clipping in
  Beamer.
- `manipulated`: original image cannot reproduce the rendered result by normal
  image placement, clipping, and live text/native shapes.

Classify conservatively, but do not over-bake:

- `a:srcRect` crop alone is direct. Record it as crop metadata for placement.
- Text overlay alone is direct.
- Simple shape overlay alone is direct for the underlying image.
- Image effects, unusual transparency effects, complex masks, or rotations that
  cannot be reproduced reliably may require a rendered crop.

## Phase 4: Refine Assets

Create one refined asset folder that contains everything a Beamer reconstruction
needs:

```text
refined/
  assets/
  refined-assets.tsv
  crop-review.tsv
  review/
  review-contact-sheet.png
```

The refined TSV should have one row per slide:

```text
slide_png    refined_assets    review_png
```

Refinement rules:

- Copy every direct original image used by a slide into `refined/assets/` as
  `original-<name>`.
- Keep original images original even if PowerPoint crops them with `a:srcRect`.
  Store the crop metadata in the structure documentation or Beamer generator.
- For images with non-reproducible image effects, crop the affected visual
  region from the rendered reference slide and save it as a rendered image
  asset.
- For simple decorative or structural shapes, record geometry and style for
  native TikZ reconstruction. Cropped shape assets may be used only as temporary
  measurement/review aids or for genuinely non-reproducible effects.
- For card-like containers, do not put the rendered card crop in the final
  refined asset set. Record the card bbox, fill, border, radius, opacity,
  z-order, and contained live text so the Beamer generator can draw it natively.
- Do not crop rendered text into final refined assets, except for temporary
  validation experiments.

`crop-review.tsv` should record:

```text
slide_png    asset    kind    bbox_px    size    status    reasons
```

Where `bbox_px` is `x0,y0,x1,y1` in rendered slide coordinates.

Generate review sheets:

- Draw the rendered slide with crop boxes.
- Show crop outputs beside the slide.
- Produce a contact sheet for all slides.

Programmatic checks:

- Every crop bbox is inside the slide.
- Every crop file exists.
- Every crop size equals `x1-x0` by `y1-y0`.
- Every refined TSV row has at least one asset unless the slide is truly blank.
- Every listed path exists.

## Phase 5: Generate Structure Markdown

Generate a Markdown structure document before Beamer construction. This becomes
the bridge between PPTX inspection and code generation.

For each slide, include:

- Rendered slide PNG path.
- Review image path.
- Asset table:
  - asset path
  - kind (`original-image`, `shape-crop`, `intrinsic-image-crop`, etc.)
  - source (`master`, `layout`, `slide`, or rendered crop)
  - PPTX shape name or reason
  - position in pixels: `x,y,width,height`
  - normalized position: `x,y,width,height`
  - notes such as `a:srcRect` crop metadata.
- Text table:
  - text box source
  - shape name
  - position in pixels
  - estimated font
  - estimated size
  - style hints
  - actual visible text.

Omit PowerPoint editor prompts such as:

- `Click to edit Master title style`
- `Click to edit Master text styles`
- slide number placeholders like `‹#›` when not resolved.

Font extraction guidance:

- Use explicit run formatting first.
- Fall back to paragraph formatting.
- If no explicit font exists, mark as inherited/estimated, e.g.
  `Roboto Condensed (estimated/inherited)`.
- Preserve bold and italic hints.

## Phase 6: Generate Admissible Beamer

The admissible Beamer target should be editable and reproducible:

- Original images are included as images.
- PowerPoint crop metadata is reproduced as clipping/pre-cropped image
  placement, not as a rendered slide crop containing text.
- Simple rectangles/round-rectangles/ellipses are native TikZ shapes.
- Card-like containers are native TikZ shapes. Do not use rendered crops for
  cards or panels, because masking baked text creates artifacts and makes the
  layout non-editable. Draw the card geometry with TikZ, then place all card
  labels, numbers, body copy, badges, and captions as live text.
- Text is live Beamer text.
- Rendered image crops are used only for non-reproducible image effects or
  approved shape assets.
- Rendered text crops are not admissible.

Use an absolute-position Beamer frame with a fixed page size matching the
reference aspect ratio:

```tex
\documentclass{beamer}
\geometry{paperwidth=960bp,paperheight=540bp,margin=0bp}
\usepackage{fontspec}
\usepackage{graphicx}
\usepackage{tikz}
\setsansfont{Roboto Condensed}
\setmainfont{Roboto Condensed}
\setbeamertemplate{navigation symbols}{}
\setbeamertemplate{headline}{}
\setbeamertemplate{footline}{}
\setbeamersize{text margin left=0pt,text margin right=0pt}
```

Native card reconstruction checklist:

- Use the reference PNG to identify the card bbox, corner radius, fill color,
  border color, border width, opacity, and stacking order.
- Draw cards with TikZ primitives such as `\path[rounded corners=..., fill=...]`
  and `draw=...` rather than `\includegraphics`.
- Place contained text with absolute text boxes or TikZ nodes, preserving
  paragraph breaks and alignment from the PPTX where available.
- Check for visual defects on each rendered slide: no masked text remnants, no
  white scars outside rounded corners, no text-object overlap, and no collapsed
  spacing between numbers, labels, and descriptions.
- Use rendered card crops only for temporary analysis or side-by-side review,
  never as the final Beamer representation of an editable card.

Important LaTeX details:

- Do not load `geometry` with package options in Beamer; Beamer already loads
  it. Use `\geometry{...}` instead.
- Compile with `latexmk -cd` so relative asset paths resolve relative to the
  generated `.tex` file.
- Use XeLaTeX for system fonts:

```bash
latexmk -cd -xelatex -interaction=nonstopmode -halt-on-error \
  -outdir="$beamer_dir/build" "$beamer_dir/deck.tex"
```

Coordinate placement pattern:

```tex
\node[anchor=north west,inner sep=0pt]
  at ([xshift=<x>\paperwidth,yshift=-<y>\paperheight]current page.north west)
  {\includegraphics[width=<w>\paperwidth,height=<h>\paperheight]{asset.png}};
```

Where `x`, `y`, `w`, and `h` are normalized fractions derived from the
1920x1080 rendered reference coordinate system.

For images with `a:srcRect`, either:

- use Beamer/TikZ clipping, or
- generate a temporary pre-cropped asset from the original image and place that.

Do not crop from the rendered slide unless the image has a non-reproducible
effect.

## Phase 7: Render And Compare Beamer Output

Render the Beamer PDF through Poppler using the same long-edge scale:

```bash
mkdir -p "$beamer_dir/rendered"
pdftoppm -png -scale-to 1920 \
  "$beamer_dir/build/deck.pdf" \
  "$beamer_dir/rendered/slide"
```

Compare against the LibreOffice reference PNGs with Pillow:

```python
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import math

rows = []
for i in range(1, slide_count + 1):
    ref = Image.open(ref_dir / f"slide-{i:02d}.png").convert("RGB")
    cand = Image.open(beamer_dir / "rendered" / f"slide-{i:02d}.png").convert("RGB")
    diff = ImageChops.difference(ref, cand)
    stat = ImageStat.Stat(diff)
    mae = sum(stat.mean) / 3
    rms = math.sqrt(sum(v * v for v in stat.rms) / 3)
    rows.append((i, mae, rms))
```

Also save amplified diff images:

```python
diff.point(lambda p: min(255, p * 4)).save(diff_dir / f"slide-{i:02d}-diff.png")
```

Use the metrics to guide iteration, but inspect diff images visually. Small
font antialiasing differences can produce nonzero pixel errors even when layout
is acceptable.

## Iteration Strategy

Work from biggest error sources to smallest:

1. Missing fonts: install or provide template fonts before tuning layout.
2. Missing background/layout/master assets.
3. Wrong image order or wrong inheritance order.
4. Incorrect `a:srcRect` handling.
5. Missing simple shapes.
6. Date/footer/slide-number placeholders that LibreOffice resolves differently
   from raw PPTX XML.
7. Text font, size, line-breaking, and autofit differences.

When a slide is visually far off, inspect:

- the reference PNG
- the Beamer-rendered PNG
- the amplified diff PNG
- the refined assets row
- the crop review row
- the generated TeX around that frame.

## Validation-Only Experiment

If the live-text Beamer result is still visibly off and you need to separate
geometry/asset errors from text-rendering errors, run a validation-only pass
that crops text regions from the reference slides and places them as images.

This pass is useful because:

- If it becomes near-perfect, geometry and asset placement are sound.
- Remaining errors are probably text engine, font metrics, placeholder
  resolution, line breaking, or antialiasing.

But this is not an admissible final Beamer reconstruction unless the user
explicitly accepts non-editable text.

## Success Criteria

The workflow is successful when:

- The PPTX has been rendered by LibreOffice to reference PNGs.
- All media parts have been extracted with `python-pptx`.
- The refined asset set contains all reusable original images and necessary
  non-text rendered assets.
- Card-like containers and simple panel shapes are reconstructed as native
  TikZ geometry with live text, not as rendered crops.
- `refined-assets.tsv` has one row per slide.
- Structure Markdown documents assets, positions, and visible text.
- The admissible Beamer deck compiles with XeLaTeX.
- Beamer-rendered PNGs are compared against the LibreOffice reference PNGs.
- Remaining differences are understood and documented, not accidental.

## Common Failure Modes

- **Off-by-one output dimensions**: caused by DPI-based rasterization. Use
  `pdftoppm -scale-to 1920`.
- **Wrong fonts**: `fc-match` falls back to another family. Install template
  fonts before tuning.
- **LaTeX geometry option clash**: Beamer already loads `geometry`. Use
  `\geometry{...}`.
- **Missing asset files during LaTeX compile**: compile with `latexmk -cd` or
  use correct paths relative to the `.tex` file.
- **Baked text in image assets**: caused by cropping rendered slide regions for
  images with text overlays. Keep original images and render text live.
- **Rendered card crops used as final assets**: causes uneditable cards, baked
  text, masking scars, and poor spacing. Rebuild cards as TikZ shapes with live
  text.
- **Over-classifying cropped images as manipulated**: `a:srcRect` is usually
  placement metadata, not a reason to use rendered slide crops.
- **Invisible placeholder prompts in structure docs**: filter out PowerPoint
  editor prompts from masters/layouts.
- **Footer/date mismatch**: LibreOffice may update or resolve placeholders at
  render time differently from raw PPTX XML.
