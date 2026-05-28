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

Planned future skills include a source-material import skill for converting
briefing documents, notes, data, and other content sources into structured
presentation inputs, and a presentation creation skill for building new decks
from an established template system.

## Current Template Capabilities

The SLAIF style currently includes semantic colors, absolute placement helpers,
rounded image rendering, title and motivation slide templates, divider slides,
and slider-table components.

The goal is to keep presentation content in deck files while moving visual
rules, layout geometry, and repeated drawing logic into reusable LaTeX style
files.
