#!/usr/bin/env bats

load helper.bash

setup() {
  load_module
}

# Test timer duration calculation function
@test "_hhg_calc_duration calculates basic duration correctly" {
  load_module
  
  # Test with simple values
  result="$(_hhg_calc_duration "1234567890.000" "1234567892.500")"
  # Normalize numeric output to 9 fractional digits to accept either "2.5" or "2.500000000"
  norm=$(printf "%.9f" "$result")
  [[ "$norm" == "2.500000000" ]]
}

@test "_hhg_calc_duration handles zero duration" {
  load_module
  
  result="$(_hhg_calc_duration "1234567890.123" "1234567890.123")"
  # Normalize output to 9 fractional digits to be tolerant to bc/fallback formatting
  norm=$(printf "%.9f" "$result")
  [[ "$norm" == "0.000000000" ]]
}

@test "_hhg_calc_duration works without bc command" {
  load_module
  
  # Mock bc to not exist
  bc() { return 127; }
  export -f bc
  
  result="$(_hhg_calc_duration "1234567890.100" "1234567892.600")"
  # Should still calculate duration using bash arithmetic
  [[ "$result" =~ ^2\.[0-9]{9}$ ]]
}

# Test time formatting function
@test "_hhg_format_time formats seconds correctly" {
  load_module
  
  # Test various time formats
  result="$(_hhg_format_time "0.123")"
  [[ "$result" == "0.123s" ]]
  
  result="$(_hhg_format_time "1.500")"
  [[ "$result" == "1.500s" ]]
  
  result="$(_hhg_format_time "65.250")"
  [[ "$result" == "1m 5.250s" ]]
  
  result="$(_hhg_format_time "3725.125")"
  [[ "$result" == "1h 2m 5.125s" ]]
}

@test "_hhg_format_time handles edge cases" {
  load_module
  
  # Test zero time
  result="$(_hhg_format_time "0")"
  [[ "$result" == "0.000s" ]]
  
  # Test very small time
  result="$(_hhg_format_time "0.001")"
  [[ "$result" == "0.001s" ]]
  
  # Test large time
  result="$(_hhg_format_time "7322.999")"
  [[ "$result" == "2h 2m 2.999s" ]]
}

# Test float comparison function
@test "_hhg_float_gt compares floats correctly" {
  load_module
  
  # Test greater than
  _hhg_float_gt "2.5" "1.0"
  [[ $? -eq 0 ]]
  
  _hhg_float_gt "1.001" "1.000"
  [[ $? -eq 0 ]]
  
  # Test not greater than
  ! _hhg_float_gt "1.0" "2.5"
  [[ $? -eq 0 ]]
  
  ! _hhg_float_gt "1.000" "1.001"
  [[ $? -eq 0 ]]
  
  # Test equal values
  ! _hhg_float_gt "1.5" "1.5"
  [[ $? -eq 0 ]]
}

@test "_hhg_float_gt works without bc command" {
  load_module
  
  # Mock bc to not exist
  bc() { return 127; }
  export -f bc
  
  _hhg_float_gt "2.5" "1.0"
  [[ $? -eq 0 ]]
  
  ! _hhg_float_gt "1.0" "2.5"
  [[ $? -eq 0 ]]
}

# Test timer integration with preexec
@test "preexec records start time when timers are enabled" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  
  # Clear any existing timer variables
  COMMAND_START_TIME=""
  COMMAND_TEXT=""
  
  # Mock date command to return predictable value
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567890.123456789"
    fi
  }
  export -f date
  
  preexec "some command"
  
  [[ "$COMMAND_START_TIME" == "1234567890.123456789" ]]
  [[ "$COMMAND_TEXT" == "some command" ]]
}

@test "preexec does not record time when timers are disabled" {
  load_module
  
  export HHGTTG_TIMERS_SET="false"
  
  # Clear any existing timer variables
  COMMAND_START_TIME=""
  COMMAND_TEXT=""
  
  preexec "some command"
  
  [[ -z "$COMMAND_START_TIME" ]]
  [[ -z "$COMMAND_TEXT" ]]
}

@test "preexec does not record time when timers are unset" {
  load_module
  
  unset HHGTTG_TIMERS_SET
  
  # Clear any existing timer variables
  COMMAND_START_TIME=""
  COMMAND_TEXT=""
  
  preexec "some command"
  
  [[ -z "$COMMAND_START_TIME" ]]
  [[ -z "$COMMAND_TEXT" ]]
}

# Test timer integration with precmd
@test "precmd displays execution time for long commands" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  COMMAND_START_TIME="1234567890.000"
  COMMAND_TEXT="long running command"
  
  # Mock date command to simulate 2.5 seconds elapsed
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567892.500"
    fi
  }
  export -f date
  
  # Capture output by running precmd in the current shell (so it clears globals)
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  
  # Should show execution time
  [[ "$output" =~ "⏱️  Execution time: 2.500s" ]]
  
  # Should clear timer variables
  [[ -z "$COMMAND_START_TIME" ]]
  [[ -z "$COMMAND_TEXT" ]]
}

@test "precmd does not display time for very quick commands" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  COMMAND_START_TIME="1234567890.000"
  COMMAND_TEXT="quick command"
  
  # Mock date command to simulate 0.0005 seconds elapsed (less than 1ms threshold)
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567890.0005"
    fi
  }
  export -f date
  
  # Capture output by running precmd in the current shell (so it clears globals)
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  
  # Should not show execution time
  [[ ! "$output" =~ "⏱️  Execution time" ]]
  
  # Should still clear timer variables
  [[ -z "$COMMAND_START_TIME" ]]
  [[ -z "$COMMAND_TEXT" ]]
}

@test "precmd shows command details for long or complex commands" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  COMMAND_START_TIME="1234567890.000"
  COMMAND_TEXT="very long command that exceeds the typical length threshold for display purposes"
  
  # Mock date command to simulate 0.5 seconds elapsed
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567890.500"
    fi
  }
  export -f date
  
  # Capture output by running precmd in the current shell (so it clears globals)
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  
  # Should show execution time and command details
  [[ "$output" =~ "⏱️  Execution time: 0.500s" ]]
  [[ "$output" =~ "Command:" ]]
  [[ "$output" =~ "very long command that exceeds" ]]
}

@test "precmd shows command details for commands taking more than 1 second" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  # Ensure test behavior is independent of default config
  export HHGTTG_EXEC_DURATION_ALERT="1.0"
  COMMAND_START_TIME="1234567890.000"
  COMMAND_TEXT="short cmd"
  
  # Mock date command to simulate 1.5 seconds elapsed
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567891.500"
    fi
  }
  export -f date
  
  # Capture output by running precmd in the current shell (so it clears globals)
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  
  # Should show execution time and command details even for short command names
  [[ "$output" =~ "⏱️  Execution time: 1.500s" ]]
  [[ "$output" =~ "Command: short cmd" ]]
}

@test "HHGTTG_EXEC_DURATION_ALERT changes execution-time threshold behavior" {
  load_module

  export HHGTTG_TIMERS_SET="true"
  # Use a short command that normally would not show details at default (1.0s)
  COMMAND_START_TIME="1234567890.000"
  COMMAND_TEXT="short cmd"

  # Mock date to simulate 0.15 seconds elapsed
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567890.150"
    fi
  }
  export -f date

  # With default threshold (1.0) the command details should NOT be shown
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  [[ ! "$output" =~ "Command:" ]]

  # Now lower the alert threshold so 0.15s exceeds it
  export HHGTTG_EXEC_DURATION_ALERT="0.1"
  COMMAND_START_TIME="1234567890.000"
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  [[ "$output" =~ "Command:" ]]
}

@test "precmd truncates very long command names" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  # Ensure test behavior is independent of default config
  export HHGTTG_EXEC_DURATION_ALERT="1.0"
  COMMAND_START_TIME="1234567890.000"
  # Create a command longer than 80 characters
  COMMAND_TEXT="this is an extremely long command that should be truncated when displayed because it exceeds the maximum display length"
  
  # Mock date command to simulate 1.5 seconds elapsed
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567891.500"
    fi
  }
  export -f date
  
  # Capture output by running precmd in the current shell (so it clears globals)
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  
  # Should show truncated command with an ellipsis
  [[ "$output" =~ "Command:" ]]
  [[ "$output" == *"..."* ]]
}

@test "precmd does not show timer when timers are disabled" {
  load_module
  
  export HHGTTG_TIMERS_SET="false"
  COMMAND_START_TIME="1234567890.000"
  COMMAND_TEXT="some command"
  
  # Mock date command
  date() {
    if [[ "$*" == "+%s.%N" ]]; then
      echo "1234567892.000"
    fi
  }
  export -f date
  
  # Capture output by running precmd in the current shell (so it clears globals)
  tmpfile="$(mktemp)"
  precmd >"$tmpfile"
  output="$(cat "$tmpfile")"
  rm -f "$tmpfile"
  
  # Should not show execution time
  [[ ! "$output" =~ "⏱️  Execution time" ]]
}

@test "precmd does not show timer when no command start time is set" {
  load_module
  
  export HHGTTG_TIMERS_SET="true"
  COMMAND_START_TIME=""
  COMMAND_TEXT=""
  
  # Capture output
  run precmd
  
  # Should not show execution time
  [[ ! "$output" =~ "⏱️  Execution time" ]]
}