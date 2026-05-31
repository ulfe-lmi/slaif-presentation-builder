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

## README protection

The logo block at the top of `README.md` is untouchable. Any change to
`README.md` must preserve both the top logo and its link exactly as they are,
including their position at the beginning of the file.

---

## Command trigger

Treat a user message as a presentation-builder command when it starts with:

```text
presentation-builder
```

Also treat the user message `help` exactly the same as:

```text
presentation-builder help
```

Command format:

```text
presentation-builder <command> [optional parameters]
```

Rules:

- Parse the first token after `presentation-builder` as the command name.
- Treat any remaining tokens as optional parameters for that command.
- If the complete user message is `help`, run `presentation-builder help`; the
  printed output must be byte-for-byte identical to `presentation-builder help`.
- If the command is unknown, print the help output.
- If no command is supplied, print the help output.
- For command outputs specified as exact text in this file, print the exact text
  and do not add commentary before or after it.

---

## Implemented commands

The currently implemented commands are:

- `presentation-builder help`
- `presentation-builder requirements`
- `presentation-builder verify`
- `presentation-builder import-source-material`
- `presentation-builder create-presentation`

Future commands must be added to both this list and the `help` command output.

---

## Command: `presentation-builder help`

Purpose:

Print all available presentation-builder commands.

Exact output:

```text
========================================
SLAIF Presentation Builder
(C) SLAIF 2026
========================================

presentation-builder commands

Usage:
  presentation-builder <command> [optional parameters]

Commands:
  Command                         Purpose
  ------------------------------  ---------------------------------------------
  help                            Print this command list.

  requirements                    Print the local software required for
                                  PowerPoint-template inspection, source
                                  material import, LibreOffice rendering,
                                  PDF/image conversion, visual comparison, and
                                  text extraction.

  verify                          Check whether the required local tools and
                                  Python packages are available. Run this after
                                  installing requirements.

  import-source-material          Inspect user-provided source files, extract
                                  useful assets into a system temporary folder,
                                  and write a markdown content dossier for
                                  presentation creation.

  create-presentation             Build a Beamer presentation from an imported
                                  content dossier, extracted assets, source
                                  documents, or a user outline; compile and
                                  inspect the rendered PDF.
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

After installing these requirements, run:
  presentation-builder verify
```

---

## Command: `presentation-builder verify`

Purpose:

Verify that the required local command-line tools and Python packages are
available for the PowerPoint-template reconstruction workflow.

Behavior:

- This command is dynamic; do not print a fixed prewritten output block.
- Run the verification locally and report the actual status of the current
  environment.
- If the repository-local virtual environment exists at `.venv`, activate it
  before checking Python packages.
- If `.venv` does not exist, check Python packages with the currently available
  `python3`.
- Check required system commands with `command -v`.
- Check required Python packages with `importlib.util.find_spec`.
- Treat `magick` as optional when `identify` and `compare` are available,
  because Ubuntu ImageMagick 6 commonly provides classic ImageMagick commands
  without the ImageMagick 7 `magick` wrapper.
- End with a clear summary:
  - `READY` if every required command and Python package is present.
  - `NOT READY` if any required command or Python package is missing.
- If the environment is not ready, list the missing commands and Python
  packages and instruct the user to install requirements before continuing.

Verification command template:

```bash
if [ -d .venv ]; then
  . .venv/bin/activate
fi

missing_commands=()

required_commands=(
  bash cp mv rm mkdir sort uniq wc realpath find xargs sed gawk grep rg file
  unzip zip jq bc python3 pip3 libreoffice soffice pdfinfo pdftoppm pdftotext
  identify convert montage compare qpdf gs tesseract fc-list latexmk
)

for command_name in "${required_commands[@]}"; do
  if command -v "${command_name}" >/dev/null 2>&1; then
    printf '%-24s OK (%s)\n' "${command_name}" "$(command -v "${command_name}")"
  else
    printf '%-24s MISSING\n' "${command_name}"
    missing_commands+=("${command_name}")
  fi
done

if command -v magick >/dev/null 2>&1; then
  printf '%-24s OK (%s)\n' "magick" "$(command -v magick)"
else
  printf '%-24s OPTIONAL (identify/compare satisfy ImageMagick requirement)\n' "magick"
fi

mapfile -t missing_python_packages < <(python3 - <<'PY'
import importlib.util

packages = {
    "pptx": "python-pptx",
    "lxml": "lxml",
    "PIL": "Pillow",
    "numpy": "numpy",
    "cv2": "opencv-python",
    "fitz": "PyMuPDF",
    "pypdf": "pypdf",
    "pdf2image": "pdf2image",
    "fontTools": "fonttools",
}

for module_name, package_name in packages.items():
    if importlib.util.find_spec(module_name) is None:
        print(package_name)
PY
)

echo
echo "Python packages:"
for package_name in python-pptx lxml Pillow numpy opencv-python PyMuPDF pypdf pdf2image fonttools; do
  missing_package=0
  for missing_name in "${missing_python_packages[@]}"; do
    if [ "${missing_name}" = "${package_name}" ]; then
      missing_package=1
      break
    fi
  done

  if [ "${missing_package}" -eq 1 ]; then
    printf '%-24s MISSING\n' "${package_name}"
  else
    printf '%-24s OK\n' "${package_name}"
  fi
done

echo
if [ "${#missing_commands[@]}" -eq 0 ] && [ "${#missing_python_packages[@]}" -eq 0 ]; then
  echo "READY"
else
  echo "NOT READY"

  if [ "${#missing_commands[@]}" -gt 0 ]; then
    printf 'Missing commands: %s\n' "${missing_commands[*]}"
  fi

  if [ "${#missing_python_packages[@]}" -gt 0 ]; then
    printf 'Missing Python packages: %s\n' "${missing_python_packages[*]}"
  fi

  echo "Install requirements, then run: presentation-builder verify"
fi
```

---

## Command: `presentation-builder import-source-material`

Purpose:

Import source material for a future presentation-building step.

Behavior:

- This command is dynamic; do not print a fixed prewritten output block.
- Use the repository skill at `skills/import-source-material/SKILL.md`.
- Treat optional command parameters as source paths, directories, page hints,
  output hints, or user constraints.
- If no source path is supplied, inspect the user request and nearby repository
  context for likely source material. If no reasonable source can be found, ask
  for the source path.
- Create a dedicated workspace in the system temporary directory.
- Copy source inputs into that temporary workspace before processing.
- Inspect source files before proposing slides.
- Extract useful images, page renders, crops, OCR text, tables, equations, and
  other reusable assets into the temporary workspace.
- Produce a markdown file named `contents.md` in the temporary workspace.
- Produce manifests for source files and extracted assets.
- End by reporting the path to `contents.md`, the temporary workspace path, the
  extracted asset directory, and any open questions.
- Do not create a Beamer deck during this command unless the user explicitly
  asks to continue into `presentation-builder create-presentation`.

Minimum expected temporary output structure:

```text
/tmp/presentation-source-import-XXXXXX/
  contents.md
  source/
  assets/
  pages/
  crops/
  ocr/
  manifests/
    source-files.tsv
    assets.tsv
```

---

## Command: `presentation-builder create-presentation`

Purpose:

Create a compiled Beamer presentation from imported material, extracted assets,
source documents, or a user-provided outline.

Behavior:

- This command is dynamic; do not print a fixed prewritten output block.
- Use the repository skill at `skills/create-presentation/SKILL.md`.
- Treat optional command parameters as paths to `contents.md`, source files,
  asset directories, target template directories, existing decks, or output
  hints.
- Prefer a previously generated `contents.md` from
  `presentation-builder import-source-material` when one is provided.
- Reuse the repository presentation template or the user-requested template.
- Preserve template-like code unless the user explicitly asks to change it.
- If the requested presentation change cannot be implemented with existing
  template elements, stop before editing and tell the user exactly what is
  missing. Ask for explicit confirmation or a design decision before either
  adding/extending reusable template elements in the style file or introducing
  any custom presentation-side element.
- Never silently choose between changing the template and adding custom
  deck-side visual code. The user must approve that direction first.
- For SLAIF Beamer decks, treat `slaif.sty` as the only valid place for
  presentation-system code. `deck.tex` is content only.
- Never introduce new visual elements, helper drawing macros, colors, repeated
  geometry, card/note/image/bar helpers, raw TikZ, direct `\drawshape`,
  direct `\placetextbox`, or direct `\includegraphics` calls in `deck.tex`.
- If a new visual element is needed while creating or refining a presentation,
  first implement or extend the reusable macro in `slaif.sty`, then call that
  macro from `deck.tex`. This applies to cards, panels, notes, footnotes,
  figures, image placement, bullet lists, bar/slider charts, timelines, tables,
  arrows, badges, dividers, and any other repeated visual structure.
- Do not misuse existing template elements just to avoid writing content
  directly. Footnote panels are for citations, source notes, and references
  only; do not put ordinary slide arguments, explanations, or bullet lists in
  footnote panels.
- If a slide needs a plain bullet list, use the existing template bullet-list
  macros directly in the slide body. Do not force bullets into panels or
  small-text panel groups when the slide design calls for ordinary bullets
  under, beside, or between other template elements.
- Before adding a new list macro, check whether the template already provides
  the needed green or blue bullet-list macro and reuse it when present.
- Before reporting a create-presentation task as complete, inspect the edited
  TeX for template-boundary violations. Newly introduced local visual helpers
  or raw layout code in `deck.tex` must be moved into `slaif.sty` first.
- Generate or update Beamer content, compile locally, render or inspect the
  output PDF, and iterate until visible layout issues are fixed.
- End by reporting the final TeX path, final PDF path, compile command, assets
  used or created, and any unresolved risks.
- Do not commit, push, or open a pull request unless the user explicitly asks.

---

## Current scope

Only the command interface and the commands above are defined at this stage.
Do not assume that additional PowerPoint reconstruction, rendering, comparison,
or deck generation commands exist until they are explicitly added to this file.
