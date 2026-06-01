# Quick Start

This repository is meant to be used through a coding agent. The
`presentation-builder` commands described in `AGENTS.md` are agent commands, not
a standalone shell executable.

Most users should start by creating a new presentation from an existing
template. Importing and clustering a new PowerPoint template is a template
engineering workflow and should come later.

## 1. Create A Presentation With The SLAIF Template

Use this when you want a new presentation that follows the SLAIF visual system.

Tell the agent which template to use before it starts editing files:

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

The agent should:

- create a new directory under `presentations/`
- copy the SLAIF showroom scaffold from `templates/slaif/`
- copy `slaif.sty` and required assets into the presentation workspace
- use `templates/slaif/slaif.tex` as the example for available template
  elements
- keep presentation content in `deck.tex`
- keep reusable visual behavior in `slaif.sty`
- compile the deck and inspect the rendered PDF

For a manual build of an existing SLAIF deck:

```bash
cd presentations/<deck-name>
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=build deck.tex
```

The PDF will be written to:

```text
presentations/<deck-name>/build/deck.pdf
```

For a quick look at the SLAIF template showroom itself:

```bash
cd templates/slaif
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=build slaif.tex
```

The showroom PDF is:

```text
templates/slaif/build/slaif.pdf
```

## 2. Create A Presentation With A Generic Beamer Theme

Use this when you do not want the SLAIF visual identity.

Tell the agent explicitly that you want standard Beamer instead of a repository
template:

```text
presentation-builder create-presentation

Use a standard Beamer theme, not the SLAIF template.
Help me choose an appropriate Beamer theme.
Create the deck under presentations/<deck-name>.
Use these source files: <paths>.
Title: <presentation title>.
Audience: <audience>.
Language: <language>.
Target length: <number of slides>.
```

The agent should first help select a Beamer theme, then create the deck under
`presentations/`. Generic Beamer decks do not use `templates/slaif/slaif.sty`
unless the user explicitly switches back to the SLAIF template.

A typical manual build is:

```bash
cd presentations/<deck-name>
latexmk -lualatex -interaction=nonstopmode -halt-on-error -outdir=build deck.tex
```

Some generic themes may also compile with `pdflatex` or `xelatex`; use the
engine selected by the deck.

## 3. Import Source Material Before Slide Creation

Use this when the content comes from PDFs, DOCX files, LaTeX sources, text
notes, screenshots, images, or mixed folders.

```text
presentation-builder import-source-material <source paths>
```

The import step should not create a deck. It should create a temporary workspace
with a structured handoff:

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

Then create the presentation from that dossier:

```text
presentation-builder create-presentation <path-to-contents.md>

Use the SLAIF template from templates/slaif.
Create the deck under presentations/<deck-name>.
```

## 4. Import And Cluster A PowerPoint Template

Use this only when you need to turn an existing PPTX visual style into a native
Beamer template.

The recommended order is:

1. `skills/import-pptx/SKILL.md`
   - render the PPTX through office tooling
   - extract slide images and embedded media
   - map source assets to rendered slides
   - build the first raw native Beamer reconstruction

2. `skills/refine-pptx-import/SKILL.md`
   - iteratively compare the native render to the PPTX render
   - keep text editable whenever possible
   - replace screenshots and one-off graphics with native shapes and assets
   - fix alignment, cropping, font sizes, and draw order

3. `skills/cluster-pptx-import/SKILL.md`
   - identify repeated visual structures in the raw deck
   - move reusable colors, panels, dividers, tables, charts, pills, and layout
     primitives into the template `.sty` file
   - keep the `.tex` deck as content and macro calls only
   - use an existing showroom such as `templates/slaif/slaif.tex` as the model
     for what belongs in the `.tex` file versus the `.sty` file

After clustering, create or update a showroom presentation for the new template.
The showroom is the agent's reference for future presentation creation.

## 5. Verify The Local Environment

Install the system tools and Python packages from `README.md`, then ask the
agent to verify the environment:

```text
presentation-builder verify
```

At minimum, Beamer workflows require a working LaTeX distribution, `latexmk`,
Poppler tools such as `pdftoppm`, ImageMagick, and the fonts used by the active
template. SLAIF decks require Roboto Condensed to be available through
fontconfig:

```bash
fc-match "Roboto Condensed"
```

