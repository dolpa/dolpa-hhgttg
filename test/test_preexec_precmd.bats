#!/usr/bin/env bats

load helper.bash

@test "_hhg_quote prints a single non-empty line" {
  load_module
  line="$(_hhg_quote)"
  [ -n "$line" ]
  [[ "$line" != *$'\n'* ]]  # only one line
}