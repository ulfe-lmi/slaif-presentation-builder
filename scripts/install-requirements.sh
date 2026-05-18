#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
VENV_DIR="${PRESENTATION_BUILDER_VENV:-${REPO_ROOT}/.venv}"

APT_PACKAGES=(
  bash
  coreutils
  findutils
  sed
  gawk
  grep
  ripgrep
  file
  unzip
  zip
  jq
  bc
  python3
  python3-venv
  python3-pip
  libreoffice
  libreoffice-impress
  poppler-utils
  imagemagick
  qpdf
  ghostscript
  tesseract-ocr
  tesseract-ocr-eng
  fontconfig
  latexmk
  texlive-latex-recommended
  texlive-latex-extra
  texlive-fonts-recommended
  texlive-xetex
  texlive-luatex
  python3-lxml
  python3-pil
  python3-numpy
  python3-opencv
  python3-pypdf
  python3-fonttools
)

PYTHON_PACKAGES=(
  python-pptx
  PyMuPDF
  pdf2image
  Pillow
  numpy
  opencv-python
  pypdf
  fonttools
  lxml
)

require_ubuntu() {
  if [[ ! -r /etc/os-release ]]; then
    echo "Cannot detect OS: /etc/os-release is missing." >&2
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "This installer is intended for Ubuntu. Detected ID=${ID:-unknown}." >&2
    exit 1
  fi
}

install_apt_packages() {
  echo "Installing apt packages..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"
}

install_python_packages() {
  echo "Creating Python virtual environment at ${VENV_DIR}..."
  python3 -m venv "${VENV_DIR}"
  "${VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel
  "${VENV_DIR}/bin/python" -m pip install "${PYTHON_PACKAGES[@]}"
}

verify_commands() {
  local commands=(
    bash
    cp
    mv
    rm
    mkdir
    sort
    uniq
    wc
    realpath
    find
    xargs
    sed
    gawk
    grep
    rg
    file
    unzip
    zip
    jq
    bc
    python3
    pip3
    libreoffice
    soffice
    pdfinfo
    pdftoppm
    pdftotext
    identify
    compare
    qpdf
    gs
    tesseract
    fc-list
    latexmk
  )

  echo
  echo "Command verification:"
  for command_name in "${commands[@]}"; do
    if command -v "${command_name}" >/dev/null 2>&1; then
      printf '  %-18s OK (%s)\n' "${command_name}" "$(command -v "${command_name}")"
    else
      printf '  %-18s MISSING\n' "${command_name}"
    fi
  done

  if command -v magick >/dev/null 2>&1; then
    printf '  %-18s OK (%s)\n' "magick" "$(command -v magick)"
  else
    printf '  %-18s NOT FOUND (Ubuntu ImageMagick may provide identify/convert/compare without magick)\n' "magick"
  fi
}

verify_python_packages() {
  echo
  echo "Python package verification in ${VENV_DIR}:"
  "${VENV_DIR}/bin/python" - <<'PY'
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
    status = "OK" if importlib.util.find_spec(module_name) else "MISSING"
    print(f"  {package_name:<18} {status}")
PY
}

main() {
  require_ubuntu
  install_apt_packages
  install_python_packages
  verify_commands
  verify_python_packages

  echo
  echo "Installation finished."
  echo "Use this Python environment for presentation-builder scripts:"
  echo "  source ${VENV_DIR}/bin/activate"
}

main "$@"
