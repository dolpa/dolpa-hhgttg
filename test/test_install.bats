#!/usr/bin/env bats
# ----------------------------------------------------------------------
#  Helpers
# ----------------------------------------------------------------------
# The helpers set up an isolated environment (HOME, TARGET_DIR, a fake repo)
# and provide a tiny wrapper to invoke the installer under test.
# ----------------------------------------------------------------------

setup() {
  # Create a fresh temporary root directory for the whole test run.
  TEST_ROOT="$(mktemp -d)"
  export TEST_ROOT

  # Simulated $HOME – the installer will treat this as the real home.
  export HOME="${TEST_ROOT}/home"
  mkdir -p "$HOME"

  # Directory that holds the installer script (relative to this .bats file).
  export SCRIPT_DIR="${BATS_TEST_DIRNAME}/.."

  # Copy the installer **and** the module files into an isolated “repo clone”.
  mkdir -p "${TEST_ROOT}/repo"
  cp -R "${SCRIPT_DIR}/." "${TEST_ROOT}/repo/"

  # All commands in the tests will be executed from this directory,
  # mimicking a real checkout.
  cd "${TEST_ROOT}/repo"

  # Where the installer will place the module files.
  export TARGET_DIR="${HOME}/.local/shell.d/hhgttg"
}

teardown() {
  # Remove the temporary hierarchy created in setup().
  rm -rf "$TEST_ROOT"
}

# -------------------------------------------------------------------------
# Run the installer (or the remover) with the isolated environment.
# The helper now forwards any arguments you give it, e.g.
#   run_installer           # → normal install
#   run_installer --remove  # → uninstall
# -------------------------------------------------------------------------
run_installer() {
  # "$@" lets the test pass any extra arguments (e.g. --remove or -r)
  run bash "${TEST_ROOT}/repo/install.sh" "$@"
}

# ----------------------------------------------------------------------
#  Tests – **Installation**
# ----------------------------------------------------------------------

@test "Installer creates TARGET_DIR" {
  run_installer
  [[ "$status" -eq 0 ]]           # installer must exit successfully
  [[ -d "$TARGET_DIR" ]]          # directory must exist
}

@test "Installer installs bash-preexec.sh, hhgttg.sh, hhgttg.config.sh" {
  run_installer
  [[ "$status" -eq 0 ]]
  [[ -f "${TARGET_DIR}/bash-preexec.sh" ]]
  [[ -f "${TARGET_DIR}/hhgttg.sh" ]]
  [[ -f "${TARGET_DIR}/hhgttg.config.sh" ]]
}

@test "Installed files have correct permissions (0644)" {
  run_installer
  [[ "$status" -eq 0 ]]

  # `stat` differs between Linux (‑c) and macOS/BSD (‑f).  Use the one that works.
  if stat --version >/dev/null 2>&1; then
    perms=$(stat -c "%a" "${TARGET_DIR}/hhgttg.sh")
  else
    perms=$(stat -f "%Lp" "${TARGET_DIR}/hhgttg.sh")
  fi
  [[ "$perms" -eq 644 ]]
}

@test "~/.bashrc receives the interactive block once" {
  run_installer
  [[ "$status" -eq 0 ]]

  bashrc="${HOME}/.bashrc"
  [[ -f "$bashrc" ]]                     # .bashrc must exist
  grep -q "# hhgttg: start" "$bashrc"
  grep -q "# hhgttg: end"   "$bashrc"
}

@test "Installer is idempotent – running twice does NOT duplicate .bashrc block" {
  run_installer
  run_installer
  bashrc="${HOME}/.bashrc"

  # There must be exactly one start‑marker (and consequently one end‑marker).
  count=$(grep -c "# hhgttg: start" "$bashrc")
  [[ "$count" -eq 1 ]]
}

@test "Installer prints completion message" {
  run_installer
  [[ "$output" == *"Installation complete."* ]]
}

# -------------------------------------------------------------------------
#  Tests – **Un‑installation** (new)
# -------------------------------------------------------------------------

# Helper that checks whether the hhgttg block is present in .bashrc
has_bashrc_block() {
  grep -qF "$BASHRC_START_MARK" "${HOME}/.bashrc"
}

@test "Uninstall (‑r/--remove) removes installed files, .bashrc block and target dir" {
  # 1️⃣  First install so we have something to remove
  run_installer
  [[ "$status" -eq 0 ]]

  # 2️⃣  Now invoke the remover
  run bash "${TEST_ROOT}/repo/install.sh" --remove
  [[ "$status" -eq 0 ]]

  # 3️⃣  All module files must be gone
  [[ ! -e "${TARGET_DIR}/bash-preexec.sh" ]]
  [[ ! -e "${TARGET_DIR}/hhgttg.sh" ]]
  [[ ! -e "${TARGET_DIR}/hhgttg.config.sh" ]]

  # 4️⃣  The interactive block must have been stripped from .bashrc
  ! grep -qF "$BASHRC_START_MARK" "${HOME}/.bashrc"
  ! grep -qF "$BASHRC_END_MARK"   "${HOME}/.bashrc"

  # 5️⃣  If the directory became empty it should be removed
  [[ ! -d "$TARGET_DIR" ]]
}

@test "Uninstall is idempotent – calling --remove twice is safe" {
  # Install first so the block/file removal can be verified
  run_installer
  [[ "$status" -eq 0 ]]

  # First removal
  run bash "${TEST_ROOT}/repo/install.sh" --remove
  [[ "$status" -eq 0 ]]

  # Second removal – should still exit cleanly and not crash
  run bash "${TEST_ROOT}/repo/install.sh" --remove
  [[ "$status" -eq 0 ]]

  # After both calls nothing should be left
  [[ ! -e "${TARGET_DIR}/bash-preexec.sh" ]]
  [[ ! -e "${TARGET_DIR}/hhgttg.sh" ]]
  [[ ! -e "${TARGET_DIR}/hhgttg.config.sh" ]]
  [[ ! -f "${HOME}/.bashrc" ]] || ! grep -qF "$BASHRC_START_MARK" "${HOME}/.bashrc"
  [[ ! -d "$TARGET_DIR" ]]
}

@test "Uninstall without prior install is safe (no‑op)" {
  # Directly call the remover – nothing has been installed yet.
  run bash "${TEST_ROOT}/repo/install.sh" --remove
  [[ "$status" -eq 0 ]]

  # No files should exist
  [[ ! -e "${TARGET_DIR}/bash-preexec.sh" ]]
  [[ ! -e "${TARGET_DIR}/hhgttg.sh" ]]
  [[ ! -e "${TARGET_DIR}/hhgttg.config.sh" ]]

  # No block in .bashrc
  [[ ! -f "${HOME}/.bashrc" ]] || ! grep -qF "$BASHRC_START_MARK" "${HOME}/.bashrc"
}