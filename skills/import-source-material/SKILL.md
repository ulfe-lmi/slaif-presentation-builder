---
name: import-source-material
description: Import user-provided source material for a future Beamer presentation by inspecting PDFs, DOCX/Word files, LaTeX, plain text, images, screenshots, and mixed inputs; extracting useful assets into a system temporary workspace; and producing a structured markdown content dossier for the presentation-building step. Use before creating slides when the presentation content must be derived from existing documents or media.
---

# Import Source Material For A Presentation

## Purpose

Use this skill to turn user-provided source files into a clean, auditable
content package for a presentation. The output is not a finished slide deck.
The output is a structured markdown dossier plus extracted assets that a later
presentation-creation step can use.

This skill is for source material such as:

- PDFs
- Word / DOCX files
- existing LaTeX
- plain text notes
- screenshots
- scanned pages
- images
- mixed folders of source documents and media
- user-written outlines or instructions

## Non-Negotiable Rules

- Inspect source files before creating or editing slides.
- Keep extracted assets in a system temporary directory unless the user asks
  for durable repository artifacts.
- Create a markdown content dossier for the imported material.
- Preserve source traceability: every proposed slide claim, figure, crop, table,
  or equation should identify the source file and page/section when available.
- Do not invent facts that are not supported by the source material.
- Prefer relevant crops, figures, and excerpts over full-page screenshots.
- If OCR is needed, mark OCR-derived text as such and inspect it for obvious
  recognition errors before using it.
- If source material is ambiguous, make the best grounded interpretation and
  record the uncertainty in the dossier.

## Required Outputs

Create a temporary workspace:

```bash
workdir="$(mktemp -d /tmp/presentation-source-import-XXXXXX)"
mkdir -p "$workdir"/{source,assets,pages,crops,ocr,manifests}
```

The import step should produce at least:

```text
$workdir/contents.md
$workdir/manifests/source-files.tsv
$workdir/manifests/assets.tsv
```

Use additional manifests when useful:

```text
$workdir/manifests/pages.tsv
$workdir/manifests/crops.tsv
$workdir/manifests/tables.tsv
$workdir/manifests/equations.tsv
```

## Recommended Markdown Dossier Structure

Write `contents.md` as the main handoff artifact:

```markdown
# Imported Presentation Source Material

## Import Summary

- Workspace:
- Source files:
- Import date:
- Requested presentation goal:
- Known constraints:

## Source Inventory

| ID | File | Type | Pages/sections | Notes |
| --- | --- | --- | --- | --- |

## Proposed Presentation Structure

1. Opening / motivation
2. Section or topic
3. Section or topic

## Slide Candidate Map

| Candidate | Proposed title | Source evidence | Suggested assets | Notes |
| --- | --- | --- | --- | --- |

## Extracted Assets

| Asset ID | File | Source | Page/region | Intended use | Notes |
| --- | --- | --- | --- | --- | --- |

## Source Text Notes

Grouped by source document, page, heading, or user-provided outline.

## Figures, Tables, Equations, And Crops

Record every reusable visual element with its extracted file path and source
location.

## Open Questions

Only include questions that materially affect presentation correctness.
```

## Workflow

### 1. Inventory Inputs

Find relevant input files from the user request and repository context:

```bash
find . -maxdepth 4 -type f | sort
```

Classify each source by file type using `file` and extension. Copy source
files into `$workdir/source/` for stable processing.

### 2. Inspect Structure

For each input, identify:

- title and authors when available
- table of contents or heading structure
- major sections and subsections
- key figures, tables, diagrams, equations, screenshots, or appendices
- pages or sections explicitly requested by the user
- material that should be omitted

For PDFs, use `pdfinfo`, `pdftotext`, `pdftoppm`, and OCR when needed:

```bash
pdfinfo source.pdf
pdftotext -layout source.pdf "$workdir/ocr/source.txt"
pdftoppm -png -scale-to 1920 source.pdf "$workdir/pages/source-page"
```

For DOCX files, inspect both extracted text and package media:

```bash
unzip -l source.docx | sort
mkdir -p "$workdir/assets/source-docx"
unzip -j source.docx 'word/media/*' -d "$workdir/assets/source-docx"
```

Use Python libraries such as `python-docx` only when available or when the user
approves installing them. Otherwise use OOXML inspection with `unzip`, `lxml`,
and text extraction tools.

For LaTeX, inspect sectioning commands, labels, figures, tables, bibliography
references, and included graphics:

```bash
rg -n '\\(part|chapter|section|subsection|begin\\{figure\\}|begin\\{table\\}|includegraphics|label\\{|ref\\{|cite\\{)' .
```

### 3. Extract Assets Into The Temporary Workspace

Extract only useful assets, and name them descriptively:

```text
$workdir/assets/source01-figure-method.png
$workdir/crops/source02-page-05-region-results.png
```

For page regions, render the page at a reproducible resolution, crop with
Python/Pillow, ImageMagick, or another deterministic tool, and record the crop
box in `crops.tsv`.

Asset manifest columns:

```text
asset_id	file	source_file	source_page_or_section	bbox_px	kind	intended_use	notes
```

Use `bbox_px` as `x0,y0,x1,y1` in the rendered page coordinate system when a
crop comes from a page image.

### 4. Build A Slide Candidate Map

Transform source structure into likely presentation structure. Prefer user
instructions when present; otherwise infer from headings, table of contents,
document emphasis, and visual assets.

Each slide candidate should record:

- proposed slide title
- source evidence
- key bullet ideas
- optional figures/tables/equations/crops
- whether the slide should be text-only, visual-first, split, table, or appendix
- open issues or missing data

Do not overload candidates. Split dense sections into multiple candidates.

### 5. Validate The Import Package

Before handing off:

- Open representative extracted page images and crops.
- Confirm crop alignment and readability.
- Confirm that `contents.md` cites the source for every major claim.
- Confirm that asset paths exist.
- Confirm that temporary workspace path is stated clearly.

## Handoff To Presentation Creation

When the import is complete, report:

- the path to `contents.md`
- the temporary workspace path
- the extracted assets directory
- any missing tools or OCR/font concerns
- any open questions that affect presentation content

Do not start creating the Beamer deck unless the user asks for the creation
step or gives permission to continue.
