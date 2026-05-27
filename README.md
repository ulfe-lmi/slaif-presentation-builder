<div style="text-align: center;">
  <a href="https://www.slaif.si">
    <img src="https://slaif.si/img/logos/SLAIF_logo_ANG_barve.svg" width="400" height="400">
  </a>
</div>

# SLAIF Presentation Builder

SLAIF Presentation Builder is a workflow and template repository for converting
existing PowerPoint presentation styles into maintainable, native Beamer/LaTeX
systems.

The project combines agent-facing skills with reusable LaTeX templates. The
current workflow covers PPTX inspection, slide rendering, asset extraction,
native Beamer reconstruction, visual refinement, and clustering repeated slide
elements into style-file macros.

## Repository Contents

- `skills/` contains agent skills for importing, refining, and clustering PPTX
  presentations.
- `templates/slaif/` contains the evolving SLAIF Beamer style.
- `source-templates/` is intended for source PowerPoint templates used as import
  targets.

## Installation

On Ubuntu, install the system tools needed for PPTX inspection, PDF/PNG
rendering, and Beamer compilation:

```bash
sudo apt-get update
sudo apt-get install -y \
  libreoffice poppler-utils imagemagick qpdf ghostscript tesseract-ocr \
  latexmk texlive-xetex texlive-latex-extra texlive-fonts-recommended \
  fonts-roboto fontconfig unzip zip jq bc ripgrep gawk
```

Install Python dependencies in a virtual environment:

```bash
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
```

For Beamer builds, the Roboto Condensed font must be available through
fontconfig. Verify it with:

```bash
fc-match "Roboto Condensed"
```

## Current Template Capabilities

The SLAIF style currently includes semantic colors, absolute placement helpers,
rounded image rendering, title and motivation slide templates, divider slides,
and slider-table components.

The goal is to keep presentation content in deck files while moving visual
rules, layout geometry, and repeated drawing logic into reusable LaTeX style
files.
