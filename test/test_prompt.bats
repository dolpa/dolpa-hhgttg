#!/usr/bin/env bats

load helper.bash

setup() {
  load_module
}

# Test the prompt theme loader function
@test "hhgttg_load_prompt sets default theme when no HHGTTG_PROMPT_THEME is set" {
  load_module
  
  unset HHGTTG_PROMPT_THEME
  
  # Mock the dontpanic prompt function to verify it's called
  hhgttg_prompt_dontpanic() { echo "dontpanic_called"; }
  export -f hhgttg_prompt_dontpanic
  
  result=$(hhgttg_load_prompt)
  [[ "$result" == "dontpanic_called" ]]
}

@test "hhgttg_load_prompt loads dontpanic theme correctly" {
  load_module
  
  export HHGTTG_PROMPT_THEME="dontpanic"
  
  # Mock the dontpanic prompt function to verify it's called
  hhgttg_prompt_dontpanic() { echo "dontpanic_called"; }
  export -f hhgttg_prompt_dontpanic
  
  result=$(hhgttg_load_prompt)
  [[ "$result" == "dontpanic_called" ]]
}

@test "hhgttg_load_prompt loads marvin theme correctly" {
  load_module
  
  export HHGTTG_PROMPT_THEME="marvin"
  
  # Mock the marvin prompt function to verify it's called
  hhgttg_prompt_marvin() { echo "marvin_called"; }
  export -f hhgttg_prompt_marvin
  
  result=$(hhgttg_load_prompt)
  [[ "$result" == "marvin_called" ]]
}

@test "hhgttg_load_prompt loads improbability theme correctly" {
  load_module
  
  export HHGTTG_PROMPT_THEME="improbability"
  
  # Mock the improbability prompt function to verify it's called
  hhgttg_prompt_improbability() { echo "improbability_called"; }
  export -f hhgttg_prompt_improbability
  
  result=$(hhgttg_load_prompt)
  [[ "$result" == "improbability_called" ]]
}

@test "hhgttg_load_prompt loads minimal theme correctly" {
  load_module
  
  export HHGTTG_PROMPT_THEME="minimal"
  
  # Mock the minimal prompt function to verify it's called
  hhgttg_prompt_minimal() { echo "minimal_called"; }
  export -f hhgttg_prompt_minimal
  
  result=$(hhgttg_load_prompt)
  [[ "$result" == "minimal_called" ]]
}

@test "hhgttg_load_prompt skips when theme is set to 'off'" {
  load_module
  
  export HHGTTG_PROMPT_THEME="off"
  
  # Should return early and not call any prompt function
  result=$(hhgttg_load_prompt)
  [[ "$result" == "" ]]
}

@test "hhgttg_load_prompt falls back to dontpanic for invalid theme" {
  load_module
  
  export HHGTTG_PROMPT_THEME="nonexistent_theme"
  
  # Mock the dontpanic prompt function to verify fallback
  hhgttg_prompt_dontpanic() { echo "fallback_to_dontpanic"; }
  export -f hhgttg_prompt_dontpanic
  
  result=$(hhgttg_load_prompt)
  [[ "$result" == "fallback_to_dontpanic" ]]
}

# Test individual prompt theme functions
@test "debug - show actual PS1 content" {
  load_module
  
  hhgttg_prompt_dontpanic
  echo "DEBUG dontpanic PS1: '$PS1'" >&3
  printf "DEBUG dontpanic PS1 hex: " >&3
  printf '%s' "$PS1" | xxd -p >&3
  
  hhgttg_prompt_marvin
  echo "DEBUG marvin PS1: '$PS1'" >&3
  printf "DEBUG marvin PS1 hex: " >&3
  printf '%s' "$PS1" | xxd -p >&3
}

@test "simplified color test" {
  load_module
  
  hhgttg_prompt_dontpanic
  
  # Let's test simpler patterns first
  [[ "$PS1" =~ "033" ]]              # Just look for 033 anywhere
  [[ "$PS1" =~ "0;34m" ]]            # Look for blue color code
  [[ "$PS1" =~ "0;32m" ]]            # Look for green color code
}

@test "simplified marvin test" {
  load_module
  
  hhgttg_prompt_marvin
  
  # Test simpler patterns
  [[ "$PS1" =~ "sigh" ]]             # Just look for sigh
  [[ "$PS1" =~ "033" ]]              # Look for color codes
  [[ "$PS1" =~ "1;30m" ]]            # Look for gray color
}

@test "hhgttg_prompt_dontpanic sets correct PS1 format" {
  load_module
  
  hhgttg_prompt_dontpanic
  
  # Check that PS1 contains expected elements
  [[ "$PS1" =~ "\w" ]]              # Contains working directory
  [[ "$PS1" =~ "DON'T PANIC" ]]      # Contains the iconic message
  [[ "$PS1" =~ "\n" ]]              # Contains newline (two-line format)
  [[ "$PS1" =~ "\$ " ]]             # Contains prompt symbol with space
}

@test "hhgttg_prompt_dontpanic contains correct colors" {
  load_module
  
  hhgttg_prompt_dontpanic
  
  # Check that PS1 contains ANSI color codes - simplified patterns
  [[ "$PS1" =~ "0;34m" ]]    # Blue color for directory
  [[ "$PS1" =~ "0;32m" ]]    # Green color for message
  [[ "$PS1" =~ "033" ]]      # ANSI escape sequence
}

@test "hhgttg_prompt_marvin sets correct PS1 format" {
  load_module
  
  hhgttg_prompt_marvin
  
  # Check that PS1 contains expected Marvin elements - simplified
  [[ "$PS1" =~ "sigh" ]]           # Contains Marvin's signature sigh
  [[ "$PS1" =~ '\w' ]]             # Contains working directory
  [[ "$PS1" =~ "What now" ]]       # Contains Marvin's pessimistic prompt
  [[ "$PS1" =~ '\n' ]]             # Contains newline (two-line format)
}

@test "hhgttg_prompt_marvin contains correct colors" {
  load_module
  
  hhgttg_prompt_marvin
  
  # Check that PS1 contains gray color scheme - simplified
  [[ "$PS1" =~ "1;30m" ]]    # Gray/dark color
  [[ "$PS1" =~ "033" ]]      # ANSI escape sequence
}

@test "hhgttg_prompt_minimal sets simple PS1 format" {
  load_module
  
  hhgttg_prompt_minimal
  
  # Check that PS1 is minimal and clean
  [[ "$PS1" == '\w $ ' ]]         # Exact minimal format
  [[ ! "$PS1" =~ "\[.*033" ]]       # No ANSI color codes
  [[ ! "$PS1" =~ "\n" ]]            # No newlines (single line)
}

@test "hhgttg_prompt_improbability sets correct PS1 format" {
  load_module
  
  hhgttg_prompt_improbability
  
  # Check that PS1 contains expected elements
  [[ "$PS1" =~ "hhgttg_improbability_message" ]]  # Contains message function call
  [[ "$PS1" =~ '\w' ]]              # Contains working directory
  [[ "$PS1" =~ "\$ " ]]             # Contains prompt symbol with space
  [[ "$PS1" =~ '\n' ]]              # Contains newline (two-line format)
}

@test "hhgttg_prompt_improbability contains correct colors" {
  load_module
  
  hhgttg_prompt_improbability
  
  # Check that PS1 contains yellow color scheme - simplified
  [[ "$PS1" =~ "0;33m" ]]    # Yellow color
  [[ "$PS1" =~ "033" ]]      # ANSI escape sequence
}

# Test the improbability message generator
@test "hhgttg_improbability_message returns non-empty message" {
  load_module
  
  result=$(hhgttg_improbability_message)
  [[ -n "$result" ]]
}

@test "hhgttg_improbability_message returns one of expected messages" {
  load_module
  
  # Run multiple times to test randomness and message variety
  local found_penguin=false
  local found_probability=false
  local found_petunias=false
  local found_reality=false
  local found_inside_out=false
  
  # Test 50 times to ensure we get different messages
  for i in {1..50}; do
    result=$(hhgttg_improbability_message)
    
    case "$result" in
      *"penguin"*)
        found_penguin=true
        ;;
      *"Probability"*)
        found_probability=true
        ;;
      *"petunias"*)
        found_petunias=true
        ;;
      *"Reality is frequently inaccurate"*)
        found_reality=true
        ;;
      *"inside out"*)
        found_inside_out=true
        ;;
    esac
  done
  
  # At least one of the expected messages should have appeared
  [[ "$found_penguin" == true || "$found_probability" == true || "$found_petunias" == true || "$found_reality" == true || "$found_inside_out" == true ]]
}

@test "hhgttg_improbability_message contains expected content" {
  load_module
  
  result=$(hhgttg_improbability_message)
  
  # Should be one of the predefined messages
  [[ "$result" == "You briefly turned into a penguin." ]] || \
  [[ "$result" == "Probability of this command succeeding: 1/∞." ]] || \
  [[ "$result" == "A bowl of petunias says hello." ]] || \
  [[ "$result" == "Reality is frequently inaccurate." ]] || \
  [[ "$result" == "You feel vaguely turned inside out." ]]
}

# Integration tests
@test "prompt functions work after module load" {
  load_module
  
  # Test that all prompt functions are available after loading
  type hhgttg_load_prompt >/dev/null
  type hhgttg_prompt_dontpanic >/dev/null
  type hhgttg_prompt_marvin >/dev/null
  type hhgttg_prompt_improbability >/dev/null
  type hhgttg_prompt_minimal >/dev/null
  type hhgttg_improbability_message >/dev/null
}

@test "prompt theme switching works correctly" {
  load_module
  
  # Test switching between different themes
  export HHGTTG_PROMPT_THEME="dontpanic"
  hhgttg_load_prompt
  local ps1_dontpanic="$PS1"
  
  export HHGTTG_PROMPT_THEME="marvin"
  hhgttg_load_prompt
  local ps1_marvin="$PS1"
  
  export HHGTTG_PROMPT_THEME="minimal"
  hhgttg_load_prompt
  local ps1_minimal="$PS1"
  
  # Each theme should produce different PS1 values
  [[ "$ps1_dontpanic" != "$ps1_marvin" ]]
  [[ "$ps1_marvin" != "$ps1_minimal" ]]
  [[ "$ps1_dontpanic" != "$ps1_minimal" ]]
}

@test "prompt configuration from config file is respected" {
  load_module
  
  # Test that the configuration value is properly loaded
  # (This assumes the config file sets HHGTTG_PROMPT_THEME)
  if [[ -n "${HHGTTG_PROMPT_THEME:-}" ]]; then
    # Should be one of the valid themes
    [[ "$HHGTTG_PROMPT_THEME" =~ ^(dontpanic|marvin|improbability|minimal|off)$ ]]
  fi
}

# Error handling tests
@test "prompt functions handle missing variables gracefully" {
  load_module
  
  # Unset the theme variable completely
  unset HHGTTG_PROMPT_THEME
  
  # Should not crash and should fall back to default
  run hhgttg_load_prompt
  [[ "$status" -eq 0 ]]
}

@test "prompt functions work with empty theme variable" {
  load_module
  
  # Set empty theme variable
  export HHGTTG_PROMPT_THEME=""
  
  # Should not crash and should fall back to default
  run hhgttg_load_prompt
  [[ "$status" -eq 0 ]]
}