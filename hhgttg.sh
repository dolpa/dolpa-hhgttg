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

# ------------------------------------------------------------------
# 0️⃣  Configuration: load the configuration
MODULE_DIR="$(dirname "${BASH_SOURCE[0]}")"
#echo MODULE_DIR=${MODULE_DIR}

CONFIG_FILE="${MODULE_DIR}/hhgttg.config.sh"
export MODULE_LOADED=false
if [ -f ${CONFIG_FILE} ]; then
#    echo -n "Loading the configuration ... "
    source "${CONFIG_FILE}"
#    if [ $MODULE_LOADED ]; then
#        echo "done"
#    else
#        echo "failed"
#    fi
fi
unset MODULE_LOADED

# ------------------------------------------------------------------
# 1️⃣  Helper: random quote -------------------------------------------------
_hhg_quote() {
    # -----------------------------------------------------------------
    #  A big, mixed‑genre list of sci‑fi movie / TV quotes.
    #  Feel free to add, delete or reorder items – just keep the array
    #  syntax intact.
    # -----------------------------------------------------------------
    local quotes=(
        # ---------- Star Wars ---------------------------------------
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
# 2️⃣  Helper: towel (optional lore) ------------------------------------
_hhg_towel() {
    # If the file does not exist, just skip output
    [[ -f "$HOME/.hhgttg/towel.txt" ]] || return
    # Prefix each line with a small bullet for visual separation
    sed -e 's/^/🔹 /' "$HOME/.hhgttg/towel.txt"
}

# ------------------------------------------------------------------
# _hhg_spinners – return a *space‑separated* list of frames.
#   * Each frame is a single “character” (emoji, Unicode glyph, ASCII)
#   * The function prints the list to STDOUT, which the caller
#     captures into an array:  local frames=($( _hhg_spinners ))
#   * You can force a particular set with HHGTTG_SPINNER_SET.
# ------------------------------------------------------------------
_hhg_spinners() {
    # ------------------------------------------------------------------
    # 1️⃣  Define all available spinner sets.
    #    Keep the syntax:  name="frame1 frame2 frame3 …"
    # ------------------------------------------------------------------
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
        
        # 3‑frame “arrow” – simple
        [timer]="⏳ ⏱️ ⏲️"
        
        [dragon]="🐍 🐉 🐲"
    )

    # ------------------------------------------------------------------
    # 2️⃣  Decide which set to use.
    # ------------------------------------------------------------------
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

    # ------------------------------------------------------------------
    # 3️⃣  Echo the space‑separated list – the caller will turn it into an array.
    # ------------------------------------------------------------------
    printf "%s" "$chosen"
}

# ------------------------------------------------------------------
# 4️⃣  Core spinner function ---------------------------------------------
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
    printf "\r\e[32m✔️  Done!%*s\e[0m\n" "$(tput cols)" ""
}
# ------------------------------------------------------------------
# 5️⃣  Hook: preexec → start spinner --------------------------------
preexec() {
    # $BASH_COMMAND contains the command line that is about to be executed.
    # $$ is the PID of the current shell – the spinner will watch **that**
    # PID because the command runs as a *child* of the shell.
    # List of commands to skip spinner
    local cmd="$1"
    local SKIP_COMMANDS=("cat"\
                         "tail"\
                         "sudo"\
                         "vim"\
                         "nano"\
                         "less"\
                         "man"\
                         "more"\
                         "top"\
                         "htop"\
                         "ssh"\
                         "bash")
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
}
# ------------------------------------------------------------------
# 6️⃣  Hook: precmd → stop spinner, show quote/towel ----------------
precmd() {
    # 1️⃣  Stop the background spinner (if any)
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        unset SPINNER_PID
    fi

    # 2️⃣  Print a colourful quote on a new line
    echo -e "\n\e[36m$(_hhg_quote)\e[0m"

    # 3️⃣  Optionally print the towel text (grey colour)
    if [[ -f "$HOME/.hhgttg/towel.txt" ]]; then
        echo -e "\e[90m$(_hhg_towel)\e[0m"
    fi
}
# ------------------------------------------------------------------
# 7️⃣  Export the hook functions for bash‑preexec to see ------------------
export -f preexec precmd spinner
# --------------------------------------------------------------------

