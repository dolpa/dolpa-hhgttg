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

# Run the installer with the isolated environment.
run_installer() {
  run bash "${TEST_ROOT}/repo/install.sh"
}


# ----------------------------------------------------------------------
#  Tests
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