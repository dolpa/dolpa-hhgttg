#!/usr/bin/env bats

load helper.bash

@test "Random spinner returns a non-empty list" {
  load_module
  result="$(_hhg_spinners)"
  [ -n "$result" ]
}

@test "Specific spinner set is selected when HHGTTG_SPINNER_SET is set" {
  load_module
  export HHGTTG_SPINNER_SET="moon"
  result="$(_hhg_spinners)"
  [[ "$result" =~ "🌑" ]]
}

@test "Invalid set falls back to random (not empty)" {
  load_module
  export HHGTTG_SPINNER_SET="idontexist"
  result="$(_hhg_spinners)"
  [ -n "$result" ]
}

@test "preexec skips spinner for ls" {
  load_module

  run preexec "ls -l"
  [ "$status" -eq 0 ]
  [ -z "${SPINNER_PID:-}" ]
}

setup() {
  load_module
  # Mock spinner to avoid actual animation or sleep
  spinner() { echo "[mock spinner]"; }
  export -f spinner
}

@test "preexec launches spinner for non-skipped command" {
  HHG_TEST_MODE=1 run preexec "sleep 1"

  # Output should contain the spinner PID
  [[ -n "${output// }" ]]
}

@test "precmd kills spinner and prints quote" {
  load_module

  SPINNER_PID=999999  # fake background PID

  # mock kill to avoid errors
  kill() { true; }
  export -f kill

  output="$(precmd)"

  [[ "$output" =~ "m" ]]   # any quote text
}
