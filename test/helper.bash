#!/usr/bin/env bash

load_module() {
  # Load module but silence output, and mock HOME to control towel file
  HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.hhgttg"

  source "$BATS_TEST_DIRNAME/../hhgttg.sh"
}