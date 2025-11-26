#!/usr/bin/env bash
#====================================================================
# HHGTTG (The Hitchhiker's Guide to the Galaxy) – Bash Spinner
#====================================================================
# This file is meant to be sourced from ~/.bashrc.
# It defines:
#   * preexec   – start a spinner in the background
#   * precmd    – kill the spinner and print a random quote/towel
#   * spinner() – the animation engine
#====================================================================

# -------------------------------------------------------------------
# 0️⃣  Configuration: load the configuration
MODULE_DIR="$(dirname "${BASH_SOURCE[0]}")"
#echo MODULE_DIR=${MODULE_DIR}

CONFIG_FILE="${MODULE_DIR}/hhgttg.config.sh"
export MODULE_LOADED=false
if [ -f "${CONFIG_FILE}" ]; then
#    echo -n "Loading the configuration ... "
    source "${CONFIG_FILE}"
#    if [ $MODULE_LOADED ]; then
#        echo "done"
#    else
#        echo "failed"
#    fi
fi
unset MODULE_LOADED

set +m

# -------------------------------------------------------------------
# 🕐  Timer variables -----------------------------------------------
COMMAND_START_TIME=""
COMMAND_TEXT=""

# -------------------------------------------------------------------
# 1️⃣  Helper: random quote -----------------------------------------
_hhg_quote() {
    # ---------------------------------------------------------------
    #  A big, mixed‑genre list of sci‑fi movie / TV quotes.
    #  Feel free to add, delete or reorder items – just keep the array
    #  syntax intact.
    # ---------------------------------------------------------------
    local quotes=(
        # ---------- Star Wars --------------------------------------
        "May the Force be with you."
        "I find your lack of faith disturbing."
        "Do. Or do not. There is no try."
        "Never tell me the odds."
        "I've got a bad feeling about this."
        "The ability to speak does not make you intelligent."
        "Your focus determines your reality."
        "In my experience, there is no such thing as luck."
        "Fear is the path to the dark side."
        "The Force will be with you, always."

        # ---------- Star Trek --------------------------------------
        "Live long and prosper."
        "Resistance is futile."
        "Make it so."
        "Beam me up, Scotty."
        "There are four lights!"
        "Logic is the beginning of wisdom, not the end."
        "The needs of the many outweigh the needs of the few."
        "Space: the final frontier."
        "Engage!"

        # ---------- Blade Runner ------------------------------------
        "All those moments will be lost in time, like tears in rain."
        "I've seen things you people wouldn't believe."
        "Replicants are like us."
        "The light that burns twice as bright burns half as long."
        "You’re a beautiful, magnificent thing."
        "I’m not in the business. I’m in the hobby."

        # ---------- The Matrix --------------------------------------
        "There is no spoon."
        "Welcome to the real world."
        "Free your mind."
        "I know kung fu."
        "What is real? How do you define it?"
        "Everything that has a beginning has an end."
        "You take the red pill, you stay in Wonderland."

        # ---------- Guardians of the Galaxy -------------------------
        "I am Groot."
        "We are Groot."
        "I'm going to be a hero."
        "You’re an odd thing, you know that?"
        "We’re in the middle of a very big deal."
        "The thing about the past is… it doesn’t exist."

        # ---------- Other sci‑fi classics ---------------------------
        "The only limit is the one you set yourself."               # Interstellar
        "In space, no one can hear you scream."                   # Alien
        "I’ll be back."                                            # Terminator
        "You’ve been a great help, thank you!"                     # The Martian
        "The future is not set. There is no fate but what we make." # Doctor Who
        "The universe is a big place, you’ll get used to it."     # 2001: A Space Odyssey
        "It’s a beautiful day to save the universe."              # Men in Black
        "You can’t handle the truth!"                              # A Few Good Men (not sci‑fi, but fun!)
        "The cake is a lie."                                       # Portal (video‑game, but iconic)
        "We’re all stories in the end."                            # Arrival
        "I’m sorry, Dave. I’m afraid I can’t do that."            # 2001: A Space Odyssey
        "We are the music makers, and we shall remain the dreamers of dreams." # The Prestige
        "The greatest trick the Devil ever pulled was convincing the world he didn't exist." # The Usual Suspects (again, non‑sci‑fi but cool)
        "You have no idea how hard it is to get a perfect cup of coffee in a galaxy far, far away." # Custom fun
    )
    # Randomly pick one and echo it
    printf "%s\n" "${quotes[RANDOM % ${#quotes[@]}]}"
}

# ------------------------------------------------------------------
# 🧮 Helper: calculate duration without bc -------------------------
_hhg_calc_duration() {
    local start_time="$1"
    local end_time="$2"
    
    # If bc is available and functional, use it for precise calculation.
    # Some environments may provide a non-working `bc` shim (e.g. exported
    # function that returns non-zero). Verify that `bc` can be executed
    # successfully before relying on it.
    if command -v bc >/dev/null 2>&1; then
        if echo "scale=9; 1+1" | bc >/dev/null 2>&1; then
            # Use bc with fixed scale to preserve nanosecond-style precision
            # (ensure 9 fractional digits are present)
            echo "scale=9; $end_time - $start_time" | bc 2>/dev/null || echo "0.000000000"
            return
        fi
    fi
    
    # Fallback: bash arithmetic (less precise but works)
    # Convert to integer nanoseconds to avoid floating point
    local start_ns="${start_time//./}"
    local end_ns="${end_time//./}"
    
    # Remove leading zeros to prevent octal interpretation
    start_ns="${start_ns#"${start_ns%%[!0]*}"}"
    end_ns="${end_ns#"${end_ns%%[!0]*}"}"
    
    # Handle empty strings (all zeros)
    [[ -z "$start_ns" ]] && start_ns="0"
    [[ -z "$end_ns" ]] && end_ns="0"
    
    # Pad to same length (nanoseconds precision)
    while [[ ${#start_ns} -lt 19 ]]; do start_ns="${start_ns}0"; done
    while [[ ${#end_ns} -lt 19 ]]; do end_ns="${end_ns}0"; done
    
    # Calculate difference in nanoseconds, then convert back
    local diff_ns=$((end_ns - start_ns))
    local seconds=$((diff_ns / 1000000000))
    local remainder=$((diff_ns % 1000000000))
    
    # Format as decimal
    printf "%d.%09d" "$seconds" "$remainder"
}

# ------------------------------------------------------------------
# 🔢 Helper: compare floating point numbers without bc -------------
_hhg_float_gt() {
    local num1="$1"
    local num2="$2"
    
    # If bc is available, use it
    if command -v bc >/dev/null 2>/dev/null; then
        # Verify bc is functional (some environments may mock or stub bc)
        if echo "1+1" | bc >/dev/null 2>&1; then
            [[ "$(echo "$num1 > $num2" | bc 2>/dev/null || echo "0")" == "1" ]]
            return
        fi
    fi
    
    # Fallback: convert to integer comparison
    # Remove decimal point
    local int1="${num1//./}"
    local int2="${num2//./}"
    
    # Remove leading zeros to prevent octal interpretation
    int1="${int1#"${int1%%[!0]*}"}"
    int2="${int2#"${int2%%[!0]*}"}"
    
    # Handle empty strings (all zeros)
    [[ -z "$int1" ]] && int1="0"
    [[ -z "$int2" ]] && int2="0"
    
    # Pad to same length for comparison
    local max_len=$((${#int1} > ${#int2} ? ${#int1} : ${#int2}))
    while [[ ${#int1} -lt $max_len ]]; do int1="${int1}0"; done
    while [[ ${#int2} -lt $max_len ]]; do int2="${int2}0"; done
    
    [[ $int1 -gt $int2 ]]
}

# ------------------------------------------------------------------
# ⏱️  Helper: format execution time --------------------------------
_hhg_format_time() {
    local total_seconds="$1"
    local hours minutes seconds milliseconds
    
    # Split into integer seconds and fractional part
    local int_seconds="${total_seconds%.*}"
    local frac_part="${total_seconds#*.}"
    
    # Handle case where there's no decimal point
    if [[ "$int_seconds" == "$total_seconds" ]]; then
        frac_part="000"
    fi
    
    # Pad fractional part to 3 digits
    frac_part="${frac_part}000"
    milliseconds="${frac_part:0:3}"
    
    hours=$((int_seconds / 3600))
    minutes=$(((int_seconds % 3600) / 60))
    seconds=$((int_seconds % 60))
    
    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %d.%03ds" "$hours" "$minutes" "$seconds" "$milliseconds"
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %d.%03ds" "$minutes" "$seconds" "$milliseconds"
    elif [[ $int_seconds -gt 0 ]]; then
        printf "%d.%03ds" "$seconds" "$milliseconds"
    else
        printf "0.%03ds" "$milliseconds"
    fi
}

# ------------------------------------------------------------------
# 2️⃣  Helper: towel (optional lore) --------------------------------
_hhg_towel() {
    # If the file does not exist, just skip output
    [[ -f "$HOME/.hhgttg/towel.txt" ]] || return
    # Prefix each line with a small bullet for visual separation
    sed -e 's/^/🔹 /' "$HOME/.hhgttg/towel.txt"
}

# ------------------------------------------------------------------
# 🎨 Prompt Theme Loader -------------------------------------------
# Loads and applies the selected prompt theme based on HHGTTG_PROMPT_THEME
# Available themes: dontpanic, marvin, improbability, minimal, off
# ------------------------------------------------------------------
hhgttg_load_prompt() {

    # Allow disabling:
    if [[ "${HHGTTG_PROMPT_THEME:-dontpanic}" == "off" ]]; then
        return 0
    fi

    case "$HHGTTG_PROMPT_THEME" in
        dontpanic)
            hhgttg_prompt_dontpanic
            ;;
        marvin)
            hhgttg_prompt_marvin
            ;;
        improbability)
            hhgttg_prompt_improbability
            ;;
        minimal)
            hhgttg_prompt_minimal
            ;;
        *)
            hhgttg_prompt_dontpanic
            ;;
    esac
}

# ------------------------------------------------------------------
# 🚀 "Don't Panic" Prompt Theme -----------------------------------
# Classic HHGTTG theme with the iconic "DON'T PANIC" message
# Features:
#   - Blue current directory path
#   - Green "(DON'T PANIC)" reminder
#   - Two-line layout for better readability
# ------------------------------------------------------------------
hhgttg_prompt_dontpanic() {
    local green="\[\033[0;32m\]"
    local blue="\[\033[0;34m\]"
    local reset="\[\033[0m\]"

    PS1="${blue}\w${reset} ${green}(DON'T PANIC)${reset}\n\$ "
}

# ------------------------------------------------------------------
# 🤖 Marvin the Paranoid Android Prompt Theme ---------------------
# Depressed robot theme inspired by Marvin from HHGTTG
# Features:
#   - Gray color scheme reflecting Marvin's melancholy
#   - Sighing indicator (*sigh*) before the path
#   - Pessimistic "What now?" prompt instead of standard $
#   - Two-line layout matching Marvin's dramatic personality
# ------------------------------------------------------------------
hhgttg_prompt_marvin() {
    local gray="\[\033[1;30m\]"
    local reset="\[\033[0m\]"

    PS1="${gray}*sigh* ${reset}\w\n${gray}What now? > ${reset}"
}

# ------------------------------------------------------------------
# 🎲 Infinite Improbability Drive Message Generator ----------------
# Generates random absurd messages inspired by the Infinite 
# Improbability Drive from HHGTTG. Called by improbability prompt.
# Returns a random message about improbable events and reality glitches.
# ------------------------------------------------------------------
hhgttg_improbability_message() {
    local msgs=(
        "You briefly turned into a penguin."
        "Probability of this command succeeding: 1/∞."
        "A bowl of petunias says hello."
        "Reality is frequently inaccurate."
        "You feel vaguely turned inside out."
    )
    echo "${msgs[RANDOM % ${#msgs[@]}]}"
}

# ------------------------------------------------------------------
# 🌀 Infinite Improbability Drive Prompt Theme --------------------
# Chaotic theme based on the Infinite Improbability Drive
# Features:
#   - Yellow color scheme suggesting energy and chaos
#   - Random improbable messages displayed above each prompt
#   - Dynamic content that changes with each command
#   - Two-line layout with absurd message on top
# ------------------------------------------------------------------
hhgttg_prompt_improbability() {
    local yellow="\[\033[0;33m\]"
    local reset="\[\033[0m\]"

    PS1="${yellow}\$(hhgttg_improbability_message)${reset}\n\w \$ "
}

# ------------------------------------------------------------------
# ⚡ Minimal Prompt Theme ------------------------------------------
# Clean, distraction-free prompt for users who prefer simplicity
# Features:
#   - No colors or decorations
#   - Single line layout: directory + prompt
#   - Standard shell prompt character ($)
#   - Maximum efficiency and minimal screen real estate usage
# ------------------------------------------------------------------
hhgttg_prompt_minimal() {
    PS1="\w \$ "
}

# -------------------------------------------------------------------
# _hhg_spinners – return a *space‑separated* list of frames.
#   * Each frame is a single “character” (emoji, Unicode glyph, ASCII)
#   * The function prints the list to STDOUT, which the caller
#     captures into an array:  local frames=($( _hhg_spinners ))
#   * You can force a particular set with HHGTTG_SPINNER_SET.
# -------------------------------------------------------------------
_hhg_spinners() {
    # ---------------------------------------------------------------
    # 1️⃣  Define all available spinner sets.
    #    Keep the syntax:  name="frame1 frame2 frame3 …"
    # ---------------------------------------------------------------
    local -A sets=(
        # Classic rotating bar (fallback if env var is empty)
        [classic]="⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈"

        # Moon phases – perfect for night‑owls
        [moon]="🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘"

        # Braille pattern – smooth, minimalistic
        [braille]="⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈"

        # Circle quadrants – the “spinning wheel” you know from many CLIs
        [circle]="◐ ◓ ◑ ◒"

        # Simple ASCII bar‑graph – looks good on every terminal
        [bars]="▁ ▂ ▃ ▄ ▅ ▆ ▇ █"

        # Growing bar – “loading…” feel
        [grow]="▏ ▎ ▍ ▌ ▋ ▊ ▉ █"

        # Traffic lights – red → orange → green (you can colour‑code them later)
        [traffic]="🔴 🟠 🟢"

        # Sci‑fi star‑ship icons
        [starship]="🛸 🚀 🛰️ 🌌"

        # Matrix‑style falling code (tiny vertical bars)
        [matrix]="｜ ⎜ ⎟ ⎠ ⎡ ⎤ ⎥ ⎦"

        # Emoji rockets with exhaust
        [rocket]="🚀 🚀💨 🚀💨💨 🚀💨💨💨"

        # 3‑dot “ellipsis” pulsing
        [ellipsis]="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"

        # Clock‑hand spinner – looks like a tiny analog clock
        [clock]="🕛 🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚"

        # Star‑wars “hyperspace” – for the Jedi in you
        [hyperspace]="⚡ ✨ 🌟 🌠"

        # 8‑direction arrows (good for “processing” feel)
        [arrows]="↖ ↗ ↘ ↙"

        # Custom “towel” theme – a nod to HHGTTG
        [towel]="🛁 🧽 🪣 🪦"

        # Unicode block elements – dense progress bar
        [blocks]="▏ ▎ ▍ ▌ ▋ ▊ ▉ █"

        # “Glitch” style – characters flicker like a bad connection
        [glitch]="▒ ▓ █ ▒ ▓ █"

        # 4‑frame “pulse” – simple yet eye‑catching
        [pulse]="⚫ ⚪ ⚫ ⚪"

        # 4‑frame “alien” – simple yet eye‑catching
        [alien]="🛸 👽 ⭐ 💫"

        # 3‑frame “arrow” – simple
        [arrow]="🔄 🔃 🔁"

        # 3‑frame “timer” – simple
        [timer]="⏳ ⏱️ ⏲️"

        # 3‑frame “dragon” – simple
        [dragon]="🐍 🐉 🐲"
    )

    # ---------------------------------------------------------------
    # 2️⃣  Decide which set to use.
    # ---------------------------------------------------------------
    local set_name="${HHGTTG_SPINNER_SET:-}"   # user‑override, may be empty
    local chosen

    # If the env var points to a valid key, use it.
    if [[ -n "$set_name" && -n "${sets[$set_name]:-}" ]]; then
        chosen="${sets[$set_name]}"
    else
        # Otherwise pick a random entry from the associative array.
        # Bash 4+ supports ${!sets[@]} to get the keys.
        local keys=("${!sets[@]}")
        chosen="${sets[${keys[RANDOM % ${#keys[@]}]}]}"
    fi

    # ---------------------------------------------------------------
    # 3️⃣  Echo the space‑separated list – the caller will turn it into an array.
    # ---------------------------------------------------------------
    printf "%s" "$chosen"
}

# -------------------------------------------------------------------
# 4️⃣  Core spinner function -----------------------------------------
spinner() {
    local pid=$1                # PID of the command we watch
    local speed="${HHGTTG_SPINNER_SPEED:-0.12}"   # seconds per frame, can be overridden
    local frames=($( _hhg_spinners ))            # turn the string into an array
    local i=0
    local colour="\e[33m"        # yellow (you can change or make it configurable)

    printf "%b" "$colour"
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r[%s] Working..." "${frames[i]}"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep "$speed"
    done
    # When the loop exits the command is finished
    local cols
    if [[ -t 1 ]]; then
        cols="$(tput cols 2>/dev/null || echo 0)"
    else
        cols=0
    fi
    printf "\r\e[32m✔️ Done!%*s\e[0m\n" "$cols" ""
}

# -------------------------------------------------------------------
# 5️⃣  Hook: preexec → start spinner --------------------------------
preexec() {
    # $BASH_COMMAND contains the command line that is about to be executed.
    # $$ is the PID of the current shell – the spinner will watch **that**
    # PID because the command runs as a *child* of the shell.
    
    # 🕐  Record command start time if timer is enabled
    local cmd="$1"
    if [[ "${HHGTTG_TIMERS_SET:-}" == "true" ]]; then
        COMMAND_START_TIME="$(date +%s.%N)"
        COMMAND_TEXT="$cmd"
    fi
    
    # List of commands to skip spinner
    local SKIP_COMMANDS=(
        apropos apt apt-get bash brew cal cat cd curl date df dnf du echo emacs \
        env ftp free head hostname htop id less ls man more nano npm pacman ping \
        pip pip3 pwd rsync scp screen sftp sh snap ssh tail tmux top traceroute \
        uname uptime vim watch wc wget whatis who whoami yum zsh zypper
)
    local skip_spin=0

    for skip in "${SKIP_COMMANDS[@]}"; do
        if [[ "$cmd" =~ ^[[:space:]]*"$skip" ]]; then
            skip_spin=1
            break  # Skip spinner
        fi
    done

    if [[ $skip_spin -eq 1 ]]; then
        return
    fi

    (spinner "$$") &
    SPINNER_PID=$!
    # TEST_MODE: output SPINNER_PID so Bats can capture it
    if [[ -n "$HHG_TEST_MODE" ]]; then
        echo "$SPINNER_PID"
    fi
}

# -------------------------------------------------------------------
# 6️⃣  Hook: precmd → stop spinner, show timer, quote/towel ----------
precmd() {
    # 1️⃣  Stop the background spinner (if any)
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        unset SPINNER_PID
    fi

    # 🕐  Calculate and display execution time if timer is enabled
    if [[ "${HHGTTG_TIMERS_SET:-}" == "true" && -n "$COMMAND_START_TIME" ]]; then
        local end_time="$(date +%s.%N)"
        local duration="$(_hhg_calc_duration "$COMMAND_START_TIME" "$end_time")"
        
        # Only show timer for commands that took some measurable time (more than 1ms)
        if _hhg_float_gt "$duration" "0.001"; then
            local formatted_time="$(_hhg_format_time "$duration")"
            echo -e "\e[35m⏱️  Execution time: $formatted_time\e[0m"
            
            # Show command if it's long or took significant time.
            # The duration threshold is configurable via HHGTTG_EXEC_DURATION_ALERT
            # (default: 1.0 seconds).
            local alert_threshold="${HHGTTG_EXEC_DURATION_ALERT:-1.0}"
            if [[ ${#COMMAND_TEXT} -gt 50 ]] || _hhg_float_gt "$duration" "$alert_threshold"; then
                local display_cmd="$COMMAND_TEXT"
                if [[ ${#display_cmd} -gt 80 ]]; then
                    display_cmd="${display_cmd:0:77}..."
                fi
                echo -e "\e[90m   Command: $display_cmd\e[0m"
            fi
        fi
        
        # Reset timer variables
        COMMAND_START_TIME=""
        COMMAND_TEXT=""
    fi

    # 2️⃣  Print a colourful quote on a new line
    echo -e "\n\e[36m$(_hhg_quote)\e[0m"

    # 3️⃣  Optionally print the towel text (grey colour)
    if [[ -f "$HOME/.hhgttg/towel.txt" ]]; then
        echo -e "\e[90m$(_hhg_towel)\e[0m"
    fi
}

# Load the selected prompt theme
hhgttg_load_prompt

# -------------------------------------------------------------------
# 7️⃣  Export the hook functions for bash‑preexec to see ------------
export -f preexec precmd spinner _hhg_format_time _hhg_calc_duration _hhg_float_gt
# -------------------------------------------------------------------