#!/usr/bin/env bash
set -euo pipefail

# Simple installer for the hhgttg bash module
# - installs files to $TARGET_DIR (default: $HOME/.local/shell.d/hhgttg)
# - downloads official bash-preexec if needed
# - idempotently adds a source block to ~/.bashrc

TARGET_DIR="${TARGET_DIR:-$HOME/.local/shell.d/hhgttg}"
PREEXEC_URL="https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
REPO_RAW_BASE="https://raw.githubusercontent.com/dolpa/dolpa-hhgttg/main"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

download() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "Neither curl nor wget is installed. Please install one and retry." >&2
    return 2
  fi
}

ensure_dir() {
  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    echo "Created $TARGET_DIR"
  fi
}

install_file() {
  local name="$1"
  local dest="$TARGET_DIR/$name"

  # Prefer local copy (when running from repo); otherwise fetch from raw GitHub
  if [ -f "$SCRIPT_DIR/$name" ]; then
    cp "$SCRIPT_DIR/$name" "$dest"
    echo "Copied local $name -> $dest"
  else
    local url
    if [ "$name" = "bash-preexec.sh" ]; then
      url="$PREEXEC_URL"
    else
      url="$REPO_RAW_BASE/$name"
    fi
    echo "Downloading $name from $url"
    if download "$url" "$dest"; then
      echo "Downloaded $name -> $dest"
    else
      echo "Failed to obtain $name" >&2
      return 1
    fi
  fi
  chmod 644 "$dest" || true
}

add_bashrc_block() {
  local bashrc="$HOME/.bashrc"
  local marker_start="# hhgttg: start"
  local marker_end="# hhgttg: end"
  local source_path="$TARGET_DIR/hhgttg.sh"

  if [ -f "$bashrc" ] && grep -Fq "$marker_start" "$bashrc"; then
    echo "A hhgttg source block already exists in $bashrc. Skipping append."
    return 0
  fi

  cat >> "$bashrc" <<EOF
$marker_start
if [ -f "$source_path" ]; then
  # Load hhgttg shell module
  source "$source_path"
fi
$marker_end
EOF

  echo "Appended hhgttg source block to $bashrc"
}

main() {
  echo "Installing hhgttg module to: $TARGET_DIR"
  ensure_dir

  # Files to install
  files=(bash-preexec.sh hhgttg.sh hhgttg.config.sh)

  for f in "${files[@]}"; do
    if ! install_file "$f"; then
      echo "Error installing $f" >&2
      exit 1
    fi
  done

  add_bashrc_block

  echo
  echo "Installation complete." 
  echo "To apply changes now, run:"
  echo "  source ~/.bashrc"
  echo "Or open a new shell session." 
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
