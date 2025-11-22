#!/usr/bin/env bash
# ----------------------------------------------------------------------
#  hhgttg – simple installer
#
#  What it does
#  -------------
#   * Installs the module files into $TARGET_DIR
#       (default: $HOME/.local/shell.d/hhgttg)
#   * Downloads the official bash‑preexec script if it is not present
#   * Idempotently adds a small interactive‑only source block to ~/.bashrc
#
#  The script is deliberately defensive – it works when run from a
#  checkout, when run from a downloaded tarball, and when run in a CI
#  container where the user’s $HOME is a temporary directory.
# ----------------------------------------------------------------------

set -euo pipefail

# ----------------------------------------------------------------------
#  Configurable constants
# ----------------------------------------------------------------------
TARGET_DIR="${TARGET_DIR:-$HOME/.local/shell.d/hhgttg}"
PREEXEC_URL="https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
REPO_RAW_BASE="https://raw.githubusercontent.com/dolpa/dolpa-hhgttg/main"

# Absolute path of the directory that contains this installer script.
# (When the installer is copied into a temporary test dir the value will
#  change accordingly, which is exactly what the test suite expects.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------------------------
#  Helper functions
# ----------------------------------------------------------------------
download() {
  # $1 – URL, $2 – destination file
  local url="$1" dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "Error: Neither curl nor wget is installed." >&2
    return 2
  fi
}

ensure_dir() {
  # Create $TARGET_DIR if it does not already exist.
  if [[ ! -d "$TARGET_DIR" ]]; then
    mkdir -p "$TARGET_DIR"
    echo "Created $TARGET_DIR"
  fi
}

install_file() {
  # $1 – filename (relative to the repo root)
  local name="$1"
  local dest="$TARGET_DIR/$name"

  # 1️⃣  Prefer a local copy (the case when we are running from a checkout)
  if [[ -f "$SCRIPT_DIR/$name" ]]; then
    cp "$SCRIPT_DIR/$name" "$dest"
    echo "Copied local $name → $dest"
  else
    # 2️⃣  No local copy → fetch from the internet
    local url
    if [[ "$name" == "bash-preexec.sh" ]]; then
      url="$PREEXEC_URL"
    else
      url="$REPO_RAW_BASE/$name"
    fi
    echo "Downloading $name from $url"
    if download "$url" "$dest"; then
      echo "Downloaded $name → $dest"
    else
      echo "Failed to obtain $name" >&2
      return 1
    fi
  fi

  # Permissions: readable by the user, not executable.
  chmod 644 "$dest" || true
}

add_bashrc_block() {
  # Append a source block to ~/.bashrc *once*.
  local bashrc="${HOME}/.bashrc"
  local marker_start="# hhgttg: start"
  local marker_end="# hhgttg: end"
  local source_path="${TARGET_DIR}/hhgttg.sh"

  # If the markers already exist we are done – this makes the installer idempotent.
  if [[ -f "$bashrc" && $(grep -F "$marker_start" "$bashrc" || true) ]]; then
    echo "A hhgttg source block already exists in $bashrc. Skipping."
    return 0
  fi

  # Ensure the file exists (touch creates an empty file if needed).
  : >> "$bashrc"

  # Write the block.  The block runs only in interactive shells (‑i).
  cat >> "$bashrc" <<EOF

$marker_start
if [[ \$- == *i* ]]; then
  # Load bash‑preexec first – required for the pre‑exec / pre‑prompt hooks.
  if [[ -f "${TARGET_DIR}/bash-preexec.sh" ]]; then
    source "${TARGET_DIR}/bash-preexec.sh"
  fi

  # Load the main hhgttg module.
  if [[ -f "${source_path}" ]]; then
    source "${source_path}"
  fi
fi
$marker_end
EOF

  echo "Appended interactive hhgttg source block to $bashrc"
}

# ----------------------------------------------------------------------
#  Main installation routine
# ----------------------------------------------------------------------
main() {
  echo "Installing hhgttg module to: $TARGET_DIR"
  ensure_dir

  # Files we want to have in $TARGET_DIR
  local files=(bash-preexec.sh hhgttg.sh hhgttg.config.sh)

  for f in "${files[@]}"; do
    if ! install_file "$f"; then
      echo "Error installing $f" >&2
      exit 1
    fi
  done

  add_bashrc_block

  echo
  echo "Installation complete."
  echo "To apply the changes now, run:"
  echo "  source ~/.bashrc"
  echo "Or open a new shell session."
}

# ----------------------------------------------------------------------
#  Run the installer when the script is executed directly.
# ----------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi