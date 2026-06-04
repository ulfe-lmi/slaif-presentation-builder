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

Start with [QUICKSTART.md](QUICKSTART.md) for the recommended order: create a
deck from an existing repository template such as SLAIF or ULFE first, use
generic Beamer when needed, and leave PPTX import/clustering for template
engineering work.

## Repository Contents

- `skills/` contains agent skills for importing, refining, and clustering PPTX
  presentations.
- `templates/slaif/` contains the SLAIF Beamer style and showroom deck.
- `templates/ulfe/` contains the ULFE Beamer style and showroom deck.
- `source-templates/` is intended for source PowerPoint templates used as import
  targets.

## Skills

The current skills support the PPTX template-import process: using an existing
PowerPoint deck as the visual base for a new native Beamer/LaTeX template.
`import-pptx` covers the initial import workflow: render the PPTX through
office tooling, inspect the file structure, extract media, map assets to slides,
and produce the first native Beamer reconstruction without baking normal text
into images. `refine-pptx-import` continues from that reconstruction and guides
iterative visual cleanup against rendered references, with emphasis on native
TikZ shapes, editable text, correct alignment, font sizing, and regression
checks. `cluster-pptx-import` then turns repeated raw Beamer/TikZ fragments into
reusable style-file macros, including colors, slide wrappers, panels, cards,
pills, progress bars, footnote panels, and other repeated graphical elements.
`insert-qr-code` supports generating real QR-code assets from user-provided
links and inserting them into existing decks through configurable template
slots.

Planned future skills include a source-material import skill for converting
briefing documents, notes, data, and other content sources into structured
presentation inputs, and a presentation creation skill for building new decks
from an established template system.

## Installation

On Ubuntu, install the system tools needed for PPTX inspection, PDF/PNG
rendering, and Beamer compilation:

```bash
sudo apt-get update
sudo apt-get install -y \
  libreoffice poppler-utils imagemagick qpdf ghostscript tesseract-ocr \
  latexmk texlive-xetex texlive-latex-extra texlive-fonts-recommended \
  fonts-roboto fontconfig unzip zip jq bc ripgrep gawk qrencode
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

## Current Templates

The repository currently includes two reusable Beamer templates:

- `templates/slaif/` for the SLAIF visual system.
- `templates/ulfe/` for the ULFE visual system reconstructed from the imported
  ULFE PowerPoint template.

The template styles keep semantic colors, placement helpers, slide layouts,
tables, charts, image treatments, dividers, and other reusable presentation
components in `.sty` files.

The goal is to keep presentation content in deck files while moving visual
rules, layout geometry, and repeated drawing logic into reusable LaTeX style
files.

## Maintainer

Janez Perš  
Faculty of Electrical Engineering, University of Ljubljana  
Laboratory for Machine Intelligence (LMI)  
Email: janez.pers@fe.uni-lj.si  

- Profile: https://lmi.fe.uni-lj.si/en/janez-pers-2/
- Laboratory: https://lmi.fe.uni-lj.si/en

## Security Contact

For responsible disclosure of vulnerabilities, please contact:  
janez.pers@fe.uni-lj.si

## Acknowledgement

We acknowledge the support of the EC/EuroHPC JU and the Slovenian Ministry of HESI via the project SLAIF (grant number 101254461).

Project website: https://www.slaif.si
