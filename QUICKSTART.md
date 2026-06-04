# Quick Start

This repository is meant to be used through a coding agent. The
`presentation-builder` commands described in `AGENTS.md` are agent commands, not
standalone shell executables.

Most users should start by creating a new presentation from an existing
template. Creating a new template from a PowerPoint file is a template
engineering workflow and should come later.

The snippets below are messages to send to the agent unless they are shown as
shell commands.

## Creating presentation from template

Use this workflow when you already have a repository template, such as
`templates/slaif` or `templates/ulfe`, or you want the agent to create a generic
Beamer deck.

### Step 1. Verify The Local Environment

Ask the agent to check the local tools:

```text
presentation-builder verify
```

The environment is ready when the command ends with:

```text
READY
```

If the command ends with `NOT READY`, install the missing tools and run the
verification again. At minimum, Beamer workflows need a working LaTeX
distribution, `latexmk`, Poppler tools such as `pdftoppm`, ImageMagick, and the
fonts used by the selected template.

For SLAIF decks, also check that Roboto Condensed is available:

```bash
fc-match "Roboto Condensed"
```

### Step 2. Import The Source Material

Start here when the content comes from PDFs, DOCX files, LaTeX sources, text
notes, screenshots, images, or mixed folders.

```text
presentation-builder import-source-material <source paths>
```

The agent should inspect the sources before proposing slides. It should create a
temporary workspace like this:

```text
/tmp/presentation-source-import-XXXXXX/
  contents.md
  source/
  assets/
  pages/
  crops/
  ocr/
  manifests/
```

The important output is `contents.md`. It is the handoff file for presentation
creation.

### Step 3. Choose The Template

Tell the agent exactly which template to use before it starts editing files.
For the SLAIF visual system, use:

```text
Use the SLAIF template from templates/slaif.
```

For the ULFE visual system, use:

```text
Use the ULFE template from templates/ulfe.
```

For a generic Beamer deck, use:

```text
Use a standard Beamer theme, not the SLAIF or ULFE template.
Help me choose an appropriate Beamer theme.
```

Repository templates should be preferred when you want a consistent visual
identity. Generic Beamer is useful for plain academic or internal drafts where
no repository template is required.

### Step 4. Create The Presentation

Create the deck from the imported dossier:

```text
presentation-builder create-presentation <path-to-contents.md>

Use the SLAIF template from templates/slaif.
Create the deck under presentations/<deck-name>.
Title: <presentation title>.
Audience: <audience>.
Language: <language>.
Target length: <number of slides>.
```

Or choose ULFE instead:

```text
presentation-builder create-presentation <path-to-contents.md>

Use the ULFE template from templates/ulfe.
Create the deck under presentations/<deck-name>.
Title: <presentation title>.
Audience: <audience>.
Language: <language>.
Target length: <number of slides>.
```

If you are skipping the import step and already know the source files, give the
agent the files directly:

```text
presentation-builder create-presentation

Use the SLAIF template from templates/slaif.
Create the deck under presentations/<deck-name>.
Use these source files: <paths>.
Title: <presentation title>.
Audience: <audience>.
Language: <language>.
Target length: <number of slides>.
```

For ULFE, replace the template line with:

```text
Use the ULFE template from templates/ulfe.
```

The agent should:

- create a new directory under `presentations/`
- copy the selected template scaffold into the presentation workspace
- copy required style files and assets into the presentation workspace
- keep presentation content in `deck.tex`
- keep reusable visual behavior in the deck-local `.sty` file
- compile the deck and inspect the rendered PDF

For repository decks, the agent should use the selected template showroom as
the usage example and the matching `.sty` file as the reusable visual system
model:

- SLAIF: `templates/slaif/slaif.tex` and `templates/slaif/slaif.sty`
- ULFE: `templates/ulfe/ulfe.tex` and `templates/ulfe/ulfe.sty`

### Step 5. Review The PDF

The finished PDF should be written to:

```text
presentations/<deck-name>/build/deck.pdf
```

For a manual rebuild of an existing deck:

```bash
cd presentations/<deck-name>
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=build deck.tex
```

Some generic themes may compile with `pdflatex` or `xelatex`; use the engine
selected by the deck.

### Step 6. Iterate On Specific Slides

When asking for fixes, point to the slide number and the visible problem:

```text
In presentations/<deck-name>/build/deck.pdf, fix slide <number>.
The issue is: <cropping, overlap, alignment, missing asset, font size, etc.>
```

The agent should render the affected slide, inspect the problem area, update the
deck or deck-local style file, recompile, and inspect the result again.

For a quick look at the SLAIF template showroom itself:

```bash
cd templates/slaif
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=build slaif.tex
```

The showroom PDF is:

```text
templates/slaif/build/slaif.pdf
```

For a quick look at the ULFE template showroom itself:

```bash
cd templates/ulfe
latexmk -xelatex -interaction=nonstopmode -halt-on-error -outdir=build ulfe.tex
```

The showroom PDF is:

```text
templates/ulfe/build/ulfe.pdf
```

## Creating new templates from .pptx

Use this workflow only when you need to turn an existing PPTX visual style into
a native Beamer template.

### Step 1. Verify The Local Environment

Ask the agent to check the local tools before importing PowerPoint files:

```text
presentation-builder verify
```

The PPTX workflow needs the same Beamer build tools as presentation creation,
plus office and image-processing tooling such as LibreOffice, Poppler,
ImageMagick, and the fonts used by the PowerPoint template.

Do not start the import until the verification command ends with:

```text
READY
```

### Step 2. Prepare The PowerPoint Source

Put the PPTX, POTX, PPT, or POT file under a dedicated folder in
`source-templates/`:

```text
source-templates/<template-name>/<template-file>.pptx
```

Use a short, stable template name. The final reusable Beamer template should
eventually live under:

```text
templates/<template-name>/
```

### Step 3. Import The PowerPoint Template

Ask the agent to run the PPTX import workflow:

```text
Use skills/import-pptx/SKILL.md.
Import source-templates/<template-name>/<template-file>.pptx.
Create the first native Beamer reconstruction for this template.
```

The agent should render the PowerPoint file through office tooling, extract
slide images and embedded media, map source assets to rendered slides, and build
the first raw Beamer reconstruction.

### Step 4. Refine The Reconstruction

Ask the agent to refine the imported deck against the rendered PowerPoint
target:

```text
Use skills/refine-pptx-import/SKILL.md.
Refine the imported <template-name> reconstruction.
Compare the native PDF render against the PowerPoint render and fix visible
differences.
```

The agent should keep text editable whenever possible, replace screenshots and
one-off graphics with native shapes or extracted assets, and fix alignment,
cropping, font sizes, and draw order.

### Step 5. Cluster The Template System

After the raw reconstruction looks visually credible, ask the agent to move
repeated structure into reusable template code:

```text
Use skills/cluster-pptx-import/SKILL.md.
Cluster the <template-name> reconstruction into a reusable Beamer template.
Use templates/slaif/slaif.tex and templates/slaif/slaif.sty as the reference
for the deck/template boundary.
```

The agent should move reusable colors, panels, dividers, tables, charts, pills,
layout primitives, and repeated geometry into the template `.sty` file. The
deck-side `.tex` file should become content and semantic macro calls only.

### Step 6. Create A Showroom

Create or update a showroom presentation for the new template:

```text
Create a showroom deck for templates/<template-name>.
Demonstrate the reusable slide layouts, panels, figure treatments, tables,
dividers, and other template elements.
Compile and inspect the showroom PDF.
```

The showroom is the agent's reference for future presentation creation. Once it
exists, future decks can use the first workflow in this quick start with:

```text
Use the <template-name> template from templates/<template-name>.
```
