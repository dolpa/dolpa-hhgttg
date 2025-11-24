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
# Requirement checkers
# ----------------------------------------------------------------------

check_bash_version() {
  local bash_version
  bash_version=$(bash --version | head -n1 | grep -oE '[0-9]+\.[0-9]+')
  local major_version=${bash_version%%.*}
  
  if [[ $major_version -lt 4 ]]; then
    echo "⚠️  WARNING: Bash version $bash_version detected. Bash 4.0+ recommended for full functionality."
    echo "   Timer and spinner features may not work properly on older Bash versions."
    return 1
  else
    echo "✅ Bash version $bash_version - OK"
    return 0
  fi
}

check_date_nanoseconds() {
  if date +%s.%N >/dev/null 2>&1; then
    local test_time
    test_time=$(date +%s.%N)
    if [[ "$test_time" =~ \.[0-9]{9}$ ]]; then
      echo "✅ Date command with nanosecond support - OK"
      return 0
    else
      echo "⚠️  WARNING: Date command doesn't provide nanosecond precision."
      echo "   Timer accuracy may be reduced."
      return 1
    fi
  else
    echo "❌ ERROR: Date command doesn't support nanosecond format (+%s.%N)."
    echo "   Timer functionality will not work properly."
    return 1
  fi
}

check_bc_command() {
  if command -v bc >/dev/null 2>&1; then
    if echo "2.5 + 1.3" | bc >/dev/null 2>&1; then
      echo "✅ BC calculator - OK (high-precision timer calculations available)"
      return 0
    else
      echo "⚠️  WARNING: BC command found but not working properly."
      echo "   Timer will use fallback calculations (reduced precision)."
      return 1
    fi
  else
    echo "⚠️  WARNING: BC calculator not found."
    echo "   Timer will use bash arithmetic (reduced precision)."
    echo "   Install with: apt install bc (Ubuntu/Debian) | brew install bc (macOS) | yum install bc (CentOS/RHEL)"
    return 1
  fi
}

check_download_tools() {
  local has_curl=0
  local has_wget=0
  
  if command -v curl >/dev/null 2>&1; then
    echo "✅ Curl - OK"
    has_curl=1
  fi
  
  if command -v wget >/dev/null 2>&1; then
    echo "✅ Wget - OK"
    has_wget=1
  fi
  
  if [[ $has_curl -eq 0 && $has_wget -eq 0 ]]; then
    echo "❌ ERROR: Neither curl nor wget found."
    echo "   Required for downloading bash-preexec.sh if not present locally."
    return 1
  fi
  
  return 0
}

check_write_permissions() {
  local target_parent
  target_parent=$(dirname "$TARGET_DIR")
  
  if [[ ! -d "$target_parent" ]]; then
    if mkdir -p "$target_parent" 2>/dev/null; then
      echo "✅ Write permissions to $target_parent - OK"
      return 0
    else
      echo "❌ ERROR: Cannot create directory $target_parent"
      echo "   Check permissions or specify different TARGET_DIR."
      return 1
    fi
  elif [[ -w "$target_parent" ]]; then
    echo "✅ Write permissions to $target_parent - OK"
    return 0
  else
    echo "❌ ERROR: No write permissions to $target_parent"
    echo "   Check permissions or specify different TARGET_DIR."
    return 1
  fi
}

check_bashrc_access() {
  local bashrc="$HOME/.bashrc"
  
  if [[ -f "$bashrc" ]]; then
    if [[ -w "$bashrc" ]]; then
      echo "✅ Write access to $bashrc - OK"
      return 0
    else
      echo "❌ ERROR: Cannot write to $bashrc"
      echo "   Check file permissions."
      return 1
    fi
  else
    local bashrc_dir
    bashrc_dir=$(dirname "$bashrc")
    if [[ -w "$bashrc_dir" ]]; then
      echo "✅ Can create $bashrc - OK"
      return 0
    else
      echo "❌ ERROR: Cannot create $bashrc in $bashrc_dir"
      echo "   Check directory permissions."
      return 1
    fi
  fi
}

check_requirements() {
  echo "🔍 Checking system requirements..."
  echo
  
  local warnings=0
  local errors=0
  
  # Essential requirements
  echo "📋 Essential Requirements:"
  check_bash_version || ((warnings++))
  check_date_nanoseconds || ((errors++))
  check_download_tools || ((errors++))
  check_write_permissions || ((errors++))
  check_bashrc_access || ((errors++))
  
  echo
  echo "🎯 Optional Requirements (for enhanced functionality):"
  check_bc_command || ((warnings++))
  
  echo
  
  if [[ $errors -gt 0 ]]; then
    echo "❌ $errors critical requirement(s) failed. Installation cannot proceed."
    echo "   Please resolve the above issues and try again."
    return 1
  elif [[ $warnings -gt 0 ]]; then
    echo "⚠️  $warnings optional requirement(s) missing. Installation can proceed but some features may be limited."
    echo "   Consider installing the missing components for full functionality."
    echo
    read -p "Continue with installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Installation cancelled."
      return 1
    fi
  else
    echo "✅ All requirements satisfied! Proceeding with installation..."
  fi
  
  echo
  return 0
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
Usage: $(basename "$0") [OPTIONS]
  (no args)        Install hhgttg module
  -r, --remove     Uninstall hhgttg module
  -c, --check      Check system requirements only (dry-run)
  -h, --help       Show this help message

Environment Variables:
  TARGET_DIR       Custom installation directory (default: ~/.local/shell.d/hhgttg)

Examples:
  $(basename "$0")                    # Install with requirement check
  $(basename "$0") --check            # Check requirements only
  TARGET_DIR="~/.config/hhgttg" $(basename "$0")  # Custom install location
EOF
    exit 0
    ;;
  -r|--remove)
    uninstall_module
    ;;
  -c|--check)
    echo "=== hhgttg Requirement Check ==="
    echo
    if check_requirements; then
      echo "🎉 System is ready for hhgttg installation!"
      exit 0
    else
      echo "❌ System requirements not met."
      exit 1
    fi
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
  echo "=== hhgttg Installation ==="
  echo
  
  # Check requirements first
  if ! check_requirements; then
    exit 1
  fi
  
  ensure_target_dir
  install_module_files
  add_bashrc_block

  echo
  echo "🎉 Installation complete!"
  echo "  • Files installed in: $TARGET_DIR"
  echo "  • Block added to: ${HOME}/.bashrc"
  echo
  echo "📝 Next steps:"
  echo "  1. Start a new shell session or run: source ~/.bashrc"
  echo "  2. Timer feature will be enabled by default (see hhgttg.config.sh to customize)"
  echo "  3. Try running a command to see the spinner and timer in action!"
  echo
  echo "🔧 Configuration file: $TARGET_DIR/hhgttg.config.sh"
  echo "📚 Documentation: README.md"
}
# ----------------------------------------------------------------------
#  Run the installer when the script is executed directly.
# ----------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi