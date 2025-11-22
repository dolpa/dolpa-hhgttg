#!/usr/bin/env bash
set -euo pipefail

LOGFILE="hhgttg_test_$(date +%s)_$RANDOM.log"

# Function to print to console no matter what
log_console() {
    echo "$@" > /dev/tty
}

log_console "==> Preparing test environment (logging to $LOGFILE)"

{
echo "==> Preparing environment for HHGTTG module tests"

### 1. Install bats-core
if [[ ! -d bats-core-master ]]; then
    echo "==> Downloading bats-core"
    curl -L -O https://github.com/bats-core/bats-core/archive/refs/heads/master.zip
    unzip master.zip
fi

if [[ ! -x /usr/local/bin/bats ]]; then
    echo "==> Installing bats-core"
    pushd bats-core-master >/dev/null
    ./install.sh /usr/local/
    popd >/dev/null
fi

### 2. Download bash-preexec.sh
echo "==> Downloading bash-preexec"
curl -sSL https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh \
    -o "./bash-preexec.sh"

### 3. Ensure bats exists
if [[ ! -x /usr/local/bin/bats ]]; then
    echo "ERROR: bats not found at /usr/local/bin/bats"
    exit 1
fi

### 4. Update PATH
export PATH="/usr/local/bin:$PATH"
echo "==> PATH updated: $PATH"

### 5. Install bats helpers
mkdir -p test_helper

if [[ ! -d test_helper/bats-support ]]; then
    echo "==> Installing bats-support"
    git clone https://github.com/bats-core/bats-support.git test_helper/bats-support
fi

if [[ ! -d test_helper/bats-assert ]]; then
    echo "==> Installing bats-assert"
    git clone https://github.com/bats-core/bats-assert.git test_helper/bats-assert
fi

### 6. Source modules
echo "==> Sourcing scripts"
source bash-preexec.sh
source hhgttg.sh

} &>"$LOGFILE"   # <-- EVERYTHING above goes to the log file

### 7. Run tests and show them live (NEVER redirected)
log_console "==> Running tests..."
TEST_RESULT=0

/usr/local/bin/bats test/ || TEST_RESULT=$?

### 8. Final message ALWAYS prints
log_console "==> All tests complete."
log_console "Log file saved at: $LOGFILE"

exit $TEST_RESULT