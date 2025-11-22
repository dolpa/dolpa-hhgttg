#!/usr/bin/env bats

# ----------------------------------------------------------------------
#  Test suite for the hhgttg installer (install.sh)
#
#  The suite creates an isolated HOME directory and a temporary copy of the
#  repository so the installer never touches the real user environment.
# ----------------------------------------------------------------------


# ----------------------------------------------------------------------
#  Helpers
# ----------------------------------------------------------------------
setup() {
  # Create a fresh temporary root directory that will hold everything.
  TEST_ROOT="$(mktemp -d)"
  export TEST_ROOT

  # Simulate a clean $HOME for the installer.
  export HOME="${TEST_ROOT}/home"
  mkdir -p "$HOME"

  # Where the installer script lives relative to this test file.
  #   BATS_TEST_DIRNAME = directory that contains this .bats file
  export SCRIPT_DIR="${BATS_TEST_DIRNAME}/.."

  # Copy the installer *and* the three module files into an isolated
  # “repo clone” – this mimics a real checkout.
  mkdir -p "${TEST_ROOT}/repo"
  cp -R "${SCRIPT_DIR}/." "${TEST_ROOT}/repo/"

  # Work from the fake repo directory – the installer uses BASH_SOURCE[0]
  # to discover its own location, so we must be inside this directory.
  cd "${TEST_ROOT}/repo"

  # Target directory used by the installer (defaults to $HOME/.local/…).
  export TARGET_DIR="${HOME}/.local/shell.d/hhgttg"
}

teardown() {
  # Remove the temporary hierarchy created in setup().
  rm -rf "$TEST_ROOT"
}

# Helper – run the installer inside the isolated environment.
run_installer() {
  run bash "${TEST_ROOT}/repo/install.sh"
}


# ----------------------------------------------------------------------
#  Tests
# ----------------------------------------------------------------------


@test "Installer creates TARGET_DIR" {
  run_installer
  [[ "$status" -eq 0 ]]                     # installer must exit cleanly
  [[ -d "$TARGET_DIR" ]]                    # target directory must exist
}

@test "Installer installs the three expected files" {
  run_installer
  [[ "$status" -eq 0 ]]

  # All three module files must be present after the run.
  [[ -f "${TARGET_DIR}/bash-preexec.sh" ]]
  [[ -f "${TARGET_DIR}/hhgttg.sh" ]]
  [[ -f "${TARGET_DIR}/hhgttg.config.sh" ]]
}

@test "Installed files have permission 0644" {
  run_installer
  [[ "$status" -eq 0 ]]

  # Use stat in a portable way – Linux: -c, macOS/BSD: -f
  if stat --version >/dev/null 2>&1; then
    perms=$(stat -c "%a" "${TARGET_DIR}/hhgttg.sh")
  else
    perms=$(stat -f "%Lp" "${TARGET_DIR}/hhgttg.sh")
  fi
  [[ "$perms" -eq 644 ]]
}

@test "~/.bashrc receives the interactive block exactly once" {
  run_installer
  [[ "$status" -eq 0 ]]

  bashrc="${HOME}/.bashrc"
  # The installer creates .bashrc if it does not already exist.
  [[ -f "$bashrc" ]]

  # Both markers must be present.
  grep -q "# hhgttg: start" "$bashrc"
  grep -q "# hhgttg: end"   "$bashrc"
}

@test "Installer is idempotent – second run does NOT duplicate .bashrc block" {
  run_installer
  run_installer

  bashrc="${HOME}/.bashrc"

  # There should be exactly one start‑marker (and therefore one end‑marker).
  count=$(grep -c "# hhgttg: start" "$bashrc")
  [[ "$count" -eq 1 ]]
}

@test "Installer prints a completion message" {
  run_installer

  # The final echo in the script contains the phrase "Installation complete."
  [[ "$output" == *"Installation complete."* ]]
}