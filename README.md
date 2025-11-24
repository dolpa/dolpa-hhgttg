# dolpa-hhgttg

HHGTTG (The Hitchhiker's Guide to the Galaxy) – Bash helper module

This small Bash module provides a lightweight set of shell helpers and configuration
for a nicer interactive Bash prompt/experience. It includes the main `hhgttg.sh` script
and a config file, and can optionally install and source `bash-preexec.sh` to enable
preexec/precmd hooks in interactive shells.

**What it does:**
- Installs / places the module files into `~/.local/shell.d/hhgttg` (or uses the local copy).
- Optionally downloads `bash-preexec.sh` (if missing) and places it alongside the module.
- Adds an idempotent sourcing block to `~/.bashrc` so the module and `bash-preexec.sh` are
	loaded for interactive shells.
- **⏱️ Timer Feature:** Displays execution time for commands that take measurable time (>1ms)
- **🎯 Smart Display:** Shows command details for long-running (>1s) or complex commands (>50 chars)
- **🎨 Spinner Animation:** Shows animated spinners during command execution
- **📜 Random Quotes:** Displays sci-fi quotes after command completion

**Included files:**
- `hhgttg.sh` — main module script (helpers, prompt spinner, etc.)
- `hhgttg.config.sh` — optional configuration overrides
- `bash-preexec.sh` — (downloaded from upstream when installing) enables preexec hooks
- `install.sh` — installer script (idempotent) that wires everything into `~/.bashrc`

**Requirements:**
- Bash (interactive shell) — tested on Bash 4.x and later
- `curl` or `wget` available to download `bash-preexec.sh` when not present locally
- Write access to your home directory to add `~/.local/shell.d/hhgttg` and modify `~/.bashrc`
- **For Timer Feature:**
  - `date` command with nanosecond support (`date +%s.%N`) — available on most modern systems
  - `bc` command (optional) — for high-precision floating-point calculations
  - `bash-preexec` — for command execution hooks (automatically installed)

**Usage:**
- To use the module without the installer, source it from your `~/.bashrc` or current session:

	```bash
	source "$HOME/.local/shell.d/hhgttg/hhgttg.config.sh"  # optional config
	source "$HOME/.local/shell.d/hhgttg/hhgttg.sh"
	```

- For immediate testing in the current shell (without editing files):

	```bash
	source ./hhgttg.config.sh
	source ./hhgttg.sh
	```

## ⏱️ Timer Feature Configuration

The module includes a powerful timer feature that tracks and displays execution time for your commands.

**Timer Configuration (in `hhgttg.config.sh`):**

```bash
# Enable/disable the timer feature
HHGTTG_TIMERS_SET=true   # Set to "false" to disable timers

# Spinner configuration (works alongside timers)
HHGTTG_SPINNER_SET=moon  # Choose spinner animation
HHGTTG_SPINNER_SPEED=0.1 # Animation speed in seconds
```

**Timer Behavior:**
- ⚡ **Smart Threshold:** Only shows timing for commands taking more than 1 millisecond
- 📊 **Detailed Display:** Shows command details for:
  - Commands with names longer than 50 characters
  - Commands taking more than 1 second to execute
- ✂️ **Smart Truncation:** Long command names (>80 chars) are truncated with "..."
- 🎨 **Color Coded:** Timer output uses purple/magenta color scheme
- 🔧 **Fallback Compatible:** Works with or without the `bc` command for calculations

**Example Timer Output:**

```bash
$ sleep 2.5
[🌑] Working...
✔️ Done!
⏱️  Execution time: 2.500s
   Command: sleep 2.5

May the Force be with you.
```

**Available Spinner Sets:**
- `moon` - Moon phases (🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘)
- `dots` - Rotating dots (⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
- `timer` - Timer symbols (⏳ ⏱️ ⏲️)
- `random` - Randomly selected spinner set

**Installation (using `install.sh`):**

The included `install.sh` automates installing the module into `~/.local/shell.d/hhgttg` and
ensures your `~/.bashrc` contains an idempotent block that sources the module and
`bash-preexec.sh` when an interactive shell starts.

Key installer behaviors:
- If the target directory does not exist, `install.sh` will create `~/.local/shell.d/hhgttg`.
- If `bash-preexec.sh` is not present locally, the installer will attempt to download the
	canonical raw file from the upstream GitHub repository using `curl` or `wget`.
- The installer appends a sourcing block to `~/.bashrc` only if an identical block is not
	already present (idempotent). The block checks for interactive shells before sourcing.

Example: run the installer from this repository directory

```bash
bash install.sh
```

What the installer adds to `~/.bashrc` (conceptual):

```bash
# >>> dolpa-hhgttg start >>>
if [[ $- == *i* ]]; then
	source "$HOME/.local/shell.d/hhgttg/bash-preexec.sh"  # if present
	source "$HOME/.local/shell.d/hhgttg/hhgttg.config.sh" 2>/dev/null || true
	source "$HOME/.local/shell.d/hhgttg/hhgttg.sh"
fi
# <<< dolpa-hhgttg end <<<
```

If you prefer to review changes before they are applied, inspect `install.sh` and run it
manually; it will print what it intends to do.

## Using `install.sh` — what it does and how to run it

This section explains the installer in a bit more detail and lists the environment
variables you can use to modify its behaviour.

Basic usage
- Run the installer from the repository directory:

```bash
bash install.sh
```

This will copy the module files into the default target directory (`$HOME/.local/shell.d/hhgttg`) and
append an interactive-only sourcing block to your `~/.bashrc` (if one is not already present).

Custom target directory
- To install to a different directory, set the `TARGET_DIR` environment variable:

```bash
TARGET_DIR="$HOME/.config/shell/hhgttg" bash install.sh
```

What the installer does (step-by-step)
- Ensures the target directory exists (creates it if missing).
- For each of these files: `bash-preexec.sh`, `hhgttg.sh`, `hhgttg.config.sh` it will
	- copy the local file from the repository when present (idempotent for local installs), or
	- download the canonical `bash-preexec.sh` from upstream when that file is not present locally.
- Appends an interactive-only sourcing block to your `~/.bashrc` so the module is only loaded for
	interactive shells. The appended block sources `bash-preexec.sh` (if available), then the optional
	`hhgttg.config.sh`, and finally `hhgttg.sh`.

Idempotency and safety
- The installer will not append the sourcing block if a block with the marker is already present
	in `~/.bashrc` (it detects the start marker `# hhgttg: start`).
- Files copied to the target directory are given permissive read permissions (`chmod 644`).

Permissions and network
- By default the installer writes into your home directory and does not require `sudo`.
- The installer only performs network downloads when `bash-preexec.sh` is not available locally.
	It uses `curl` (preferred) or `wget` if available.

Quick troubleshooting
- After installing, either start a new shell or run `source ~/.bashrc` to load the module immediately.
- If you use a different profile file (for example `~/.bash_profile` or `~/.profile`), move the
	appended block there or adapt the script before running.
- If the spinner/quotes do not appear, ensure you are running Bash 4+ (macOS default Bash is 3.2).

**Timer Feature Troubleshooting:**
- **Timers not showing:** Ensure `HHGTTG_TIMERS_SET=true` in `hhgttg.config.sh`
- **Inaccurate timing:** Install `bc` command for high-precision calculations:
  - Ubuntu/Debian: `sudo apt install bc`
  - macOS: `brew install bc` (or use built-in)
  - CentOS/RHEL: `sudo yum install bc`
- **No nanosecond precision:** Ensure your `date` command supports `+%s.%N` format
- **Commands not timed:** Check that `bash-preexec` is properly loaded and functioning
- **Timer showing for quick commands:** This is normal for the first few commands as the system calibrates

Example installer output (typical):

```
Installing hhgttg module to: /Users/you/.local/shell.d/hhgttg
Created /Users/you/.local/shell.d/hhgttg
Copied local hhgttg.sh -> /Users/you/.local/shell.d/hhgttg/hhgttg.sh
Copied local hhgttg.config.sh -> /Users/you/.local/shell.d/hhgttg/hhgttg.config.sh
Downloading bash-preexec.sh from https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
Downloaded bash-preexec.sh -> /Users/you/.local/shell.d/hhgttg/bash-preexec.sh
Appended interactive hhgttg source block to /Users/you/.bashrc

Installation complete.
To apply changes now, run:
	source ~/.bashrc
```

Uninstall
- To remove the module, delete the target directory (default `~/.local/shell.d/hhgttg`) and
	remove the `# hhgttg: start` / `# hhgttg: end` block from your shell profile.


**Uninstall / remove:**
- Remove or comment out the sourcing block from `~/.bashrc` and delete
	`~/.local/shell.d/hhgttg` if you no longer need the module.

**Support / notes:**
- The installer requires network access only if `bash-preexec.sh` needs to be downloaded.
- If your system uses a different profile file (e.g., `~/.bash_profile`), add the
	sourcing block there instead or adapt `install.sh` accordingly.

Enjoy — and whatever you do, don’t panic! 
Meanwhile, my blog and socials are just sitting there, waiting for attention:
- 🌐 **Blog:** [dolpa.me](https://dolpa.me)
- 📡 **RSS Feed:** [Subscribe via RSS](https://dolpa.me/rss)
- 🐙 **GitHub:** [dolpa on GitHub](https://github.com/dolpa)
- 📘 **Facebook:** [Facebook Page](https://www.facebook.com/dolpa79)
- 🐦 **Twitter (X):** [Twitter Profile](https://x.com/_dolpa)
- 💼 **LinkedIn:** [LinkedIn Profile](https://www.linkedin.com/in/paveldolinin/)
- 👽 **Reddit:** [Reddit Profile](https://www.reddit.com/user/Accomplished_Try_928/)
- 💬 **Telegram:** [Telegram Channel](https://t.me/dolpa_me)
- ▶️ **YouTube:** [YouTube Channel](https://www.youtube.com/c/PavelDolinin)
