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

**Included files:**
- `hhgttg.sh` — main module script (helpers, prompt spinner, etc.)
- `hhgttg.config.sh` — optional configuration overrides
- `bash-preexec.sh` — (downloaded from upstream when installing) enables preexec hooks
- `install.sh` — installer script (idempotent) that wires everything into `~/.bashrc`

**Requirements:**
- Bash (interactive shell) — tested on Bash 4.x and later
- `curl` or `wget` available to download `bash-preexec.sh` when not present locally
- Write access to your home directory to add `~/.local/shell.d/hhgttg` and modify `~/.bashrc`

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
- 🐙 **GitHub:** [pdolinin on GitHub](https://github.com/dolpa)
- 📘 **Facebook:** [Your Facebook Page](https://www.facebook.com/dolpa79)
- 🐦 **Twitter (X):** [Your Twitter Profile](https://x.com/_dolpa)
- 💼 **LinkedIn:** [Your LinkedIn Profile](https://www.linkedin.com/in/paveldolinin/)
- 👽 **Reddit:** [Your Reddit Profile](https://www.reddit.com/user/Accomplished_Try_928/)
- 💬 **Telegram:** [Your Telegram Channel](https://t.me/dolpa_me)
- ▶️ **YouTube:** [Your YouTube Channel](https://www.youtube.com/c/PavelDolinin)
