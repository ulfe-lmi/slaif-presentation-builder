## Purpose

This repository defines a command-oriented workflow for a coding agent that builds
presentations from existing PowerPoint templates.

The agent is not limited to a prepared Beamer template. The intended workflow is:

1. Inspect an existing PowerPoint template with local Python tooling.
2. Render the template through LibreOffice.
3. Analyze the rendered slides as visual targets.
4. Reconstruct a presentation system that can reproduce the imported PowerPoint
   template as closely as possible.
5. Build new presentation content using that reconstructed visual system.

The interaction model is a lightweight command-line interface inside the coding
agent. Commands are triggered by messages that begin with `presentation-builder`.

---

## Command trigger

Treat a user message as a presentation-builder command when it starts with:

```text
presentation-builder
```

Command format:

```text
presentation-builder <command> [optional parameters]
```

Rules:

- Parse the first token after `presentation-builder` as the command name.
- Treat any remaining tokens as optional parameters for that command.
- If the command is unknown, print the help output.
- If no command is supplied, print the help output.
- For command outputs specified as exact text in this file, print the exact text
  and do not add commentary before or after it.

---

## Implemented commands

The currently implemented commands are:

- `presentation-builder help`
- `presentation-builder requirements`

Future commands must be added to both this list and the `help` command output.

---

## Command: `presentation-builder help`

Purpose:

Print all available presentation-builder commands.

Exact output:

```text
presentation-builder commands

Usage:
  presentation-builder <command> [optional parameters]

Commands:
  help
      Print this command list.

  requirements
      Print the local software required for PowerPoint-template inspection,
      LibreOffice rendering, PDF/image conversion, visual comparison, and text
      extraction.
```

---

## Command: `presentation-builder requirements`

Purpose:

Print the local software that must be installed before the PowerPoint-template
reconstruction workflow can run reliably.

Exact output:

```text
presentation-builder local requirements

Required system tools:
  bash
      POSIX-compatible shell used to run repeatable inspection and build steps.

  coreutils
      Provides standard commands such as cp, mv, rm, mkdir, sort, uniq, wc, and
      realpath.

  findutils
      Provides find and xargs for locating template files and generated assets.

  sed
      Required for small deterministic text transformations.

  gawk
      Required for structured command-line text processing.

  grep
      Required baseline text search tool.

  ripgrep
      Required fast recursive text search tool; executable name: rg.

  file
      Required for detecting file types and MIME-like metadata.

  unzip
      Required for inspecting PPTX, DOCX, and other OOXML zip containers.

  zip
      Required for rebuilding OOXML containers when needed.

  jq
      Required for reading and writing JSON inspection manifests.

  bc
      Required for deterministic numeric calculations in shell scripts.

Required Python runtime:
  python3 >= 3.10
      Required runtime for template inspection, geometry extraction, image
      analysis, and asset generation.

  python3-venv
      Required for isolated project environments.

  pip
      Required for installing Python packages.

Required Python packages:
  python-pptx
      Inspect PPTX slide masters, layouts, placeholders, theme references,
      shapes, text runs, and media relationships.

  lxml
      Parse and inspect raw OOXML parts that python-pptx does not expose.

  Pillow
      Read, crop, resize, and compare raster images.

  numpy
      Numeric image and geometry processing.

  opencv-python
      Pixel-level image comparison, feature detection, edge detection, and
      crop/region analysis.

  PyMuPDF
      Render, inspect, and crop PDF pages from Python; import name: fitz.

  pypdf
      Inspect and manipulate PDF structure when raster rendering is not enough.

  pdf2image
      Python wrapper around Poppler PDF-to-image conversion.

  fonttools
      Inspect font metadata and map PowerPoint font references to local fonts.

Required office tooling:
  LibreOffice
      Required for importing and rendering PowerPoint files. The command-line
      executable must be available as libreoffice or soffice.

  LibreOffice Impress
      Required LibreOffice component for PPTX/PPT/POTX/POT rendering.

Required PDF and image tooling:
  poppler-utils
      Required for pdfinfo and pdftoppm. Used for PDF metadata inspection and
      PDF-to-PNG conversion.

  ImageMagick
      Required for identify, convert or magick, montage, and compare during
      image inspection and visual-difference checks.

  qpdf
      Required for validating and normalizing PDFs.

  ghostscript
      Required by parts of the PDF/image toolchain and for PDF repair or
      conversion fallback.

Required OCR/text extraction tooling:
  tesseract-ocr
      Required for OCR on scanned slides, screenshots, and rendered template
      images when embedded text cannot be extracted directly.

  poppler-utils
      Provides pdftotext for text extraction from rendered or source PDFs.

Required font tooling:
  fontconfig
      Required for fc-list, fc-match, and font cache management.

  Template fonts
      Every font used by the PowerPoint template must be installed locally.
      Exact visual reproduction is not possible when LibreOffice substitutes
      missing fonts.

Required LaTeX tooling for generated Beamer output:
  TeX Live or another complete LaTeX distribution
      Required when the reconstructed presentation system emits Beamer or other
      LaTeX output.

  latexmk
      Required for repeatable LaTeX compilation.

Recommended verification commands:
  python3 --version
  python3 -m pip --version
  libreoffice --version
  soffice --version
  pdfinfo -v
  pdftoppm -v
  magick -version
  identify -version
  compare -version
  qpdf --version
  gs --version
  tesseract --version
  fc-list --version
  latexmk --version
  rg --version
  jq --version
```

---

## Current scope

Only the command interface and the two commands above are defined at this stage.
Do not assume that PowerPoint reconstruction, rendering, comparison, or deck
generation commands exist until they are explicitly added to this file.
