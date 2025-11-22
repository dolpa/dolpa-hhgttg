#!/usr/bin/env bash
# ----------------------------------------------------------------------
# hhgttg installer / remover
# ----------------------------------------------------------------------

set -euo pipefail

# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------
MODULE_FILES=(
  "bash-preexec.sh"
  "hhgttg.sh"
  "hhgttg.config.sh"
)

BASHRC_START_MARK="# hhgttg: start"
BASHRC_END_MARK="# hhgttg: end"

TARGET_DIR="${TARGET_DIR:-$HOME/.local/shell.d/hhgttg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() {
  printf '%s\n' "$1" >&2
  exit "${2:-1}"
}

# ----------------------------------------------------------------------
# Install helpers
# ----------------------------------------------------------------------

ensure_target_dir() {
  if [[ ! -d "$TARGET_DIR" ]]; then
    mkdir -p "$TARGET_DIR"
    echo "Created target directory: $TARGET_DIR"
  fi
}

install_module_files() {
  for file in "${MODULE_FILES[@]}"; do
    local src="${SCRIPT_DIR}/${file}"
    local dst="${TARGET_DIR}/${file}"

    if [[ -f "$src" ]]; then
      cp -f "$src" "$dst"
    else
      if [[ "$file" == "bash-preexec.sh" ]]; then
        echo "Downloading $file ..."
        if command -v curl >/dev/null 2>&1; then
          curl -fsSL "https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh" -o "$dst"
        elif command -v wget >/dev/null 2>&1; then
          wget -qO "$dst" "https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
        else
          die "Cannot download $file – neither curl nor wget found."
        fi
      else
        die "File not found: ${src}"
      fi
    fi
    chmod 0644 "$dst"
    echo "Installed $file → $dst"
  done
}

add_bashrc_block() {
  local bashrc="$HOME/.bashrc"

  [[ -f "$bashrc" ]] || touch "$bashrc"

  if grep -qF "$BASHRC_START_MARK" "$bashrc"; then
    echo "Block already exists – skipping"
    return
  fi

  cat >>"$bashrc" <<EOF

$BASHRC_START_MARK
if [[ -n "\$PS1" ]]; then
  export PATH="\$PATH:${TARGET_DIR}"
  [[ -f "${TARGET_DIR}/hhgttg.sh" ]] && source "${TARGET_DIR}/hhgttg.sh"
fi
$BASHRC_END_MARK
EOF

  echo "Added interactive block to $bashrc"
}

# ----------------------------------------------------------------------
# Uninstall helpers
# ----------------------------------------------------------------------

remove_bashrc_block() {
  local bashrc="$HOME/.bashrc"
  [[ -f "$bashrc" ]] || return 0

  if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i "/$BASHRC_START_MARK/,/$BASHRC_END_MARK/d" "$bashrc"
  else
    # BSD/macOS sed
    sed -i '' "/$BASHRC_START_MARK/,/$BASHRC_END_MARK/d" "$bashrc"
  fi

  echo "Removed block from $bashrc (if present)"
}

uninstall_module() {
  echo "=== hhgttg – Uninstall ==="

  for file in "${MODULE_FILES[@]}"; do
    local f="${TARGET_DIR}/${file}"
    if [[ -e "$f" ]]; then
      rm -f "$f"
      echo "Removed $f"
    fi
  done

  remove_bashrc_block

  if [[ -d "$TARGET_DIR" && -z "$(ls -A "$TARGET_DIR")" ]]; then
    rmdir "$TARGET_DIR"
    echo "Removed empty directory $TARGET_DIR"
  else
    echo "Directory not empty – leaving $TARGET_DIR"
  fi

  echo "=== uninstall complete ==="
  exit 0
}

# ----------------------------------------------------------------------
# Argument parser
# ----------------------------------------------------------------------

arg="${1:-}"

case "$arg" in
  -h|--help)
    cat <<EOF
Usage: $(basename "$0") [--remove|-r]
  (no args)   Install
  -r,--remove Uninstall
EOF
    exit 0
    ;;
  -r|--remove)
    uninstall_module
    ;;
  "" )
    # continue to install
    ;;
  *)
    die "Unknown option: $arg"
    ;;
esac

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

main() {
  ensure_target_dir
  install_module_files
  add_bashrc_block

  echo
  echo "Installation complete."
  echo "  • Files installed in: $TARGET_DIR"
  echo "  • Block added to: ${HOME}/.bashrc"
}
# ----------------------------------------------------------------------
#  Run the installer when the script is executed directly.
# ----------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi