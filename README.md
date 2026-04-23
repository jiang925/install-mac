# install-mac

Personal one-shot bootstrap for a fresh Mac. Public so I can `curl`-pipe it from anywhere; private secrets stay in [`jiang925/dotfiles`](https://github.com/jiang925/dotfiles) (chezmoi + age).

## Run

Pin to a known-good commit (recommended):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiang925/install-mac/<sha>/bootstrap.sh)"
```

Or run HEAD:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiang925/install-mac/main/bootstrap.sh)"
```

## What it does

**Stage 1 — public, no secrets**
1. `xcode-select --install` (waits for the GUI dialog to complete)
2. Install Homebrew (Apple Silicon + Intel paths)
3. `brew bundle` against [`Brewfile`](./Brewfile) — CLI tools, casks, mas apps
4. Install [`configs/ghostty.config`](./configs/ghostty.config) into both `~/.config/ghostty/config` and the Ghostty app-support path — read by both `ghostty` and `cmux`
5. `gh auth login --web` — opens a browser for OAuth, token lands in macOS Keychain
6. `gh auth setup-git` — git uses the gh token for HTTPS clones

Both `bootstrap.sh` and `macos-defaults.sh` detect VMs (VMware/Parallels/VirtualBox/QEMU) via `sysctl hw.model` + `ioreg`. On VMs the following are skipped: `1password`, `1password-cli`, `logi-options-plus`, and the Dock autohide tweaks — they're either irrelevant on a guest or better handled from the host.

**Stage 2 — private, handed off to chezmoi**
6. `chezmoi init --apply jiang925` — clones the private dotfiles repo
7. chezmoi's `run_once_before_01-setup-1password.sh.tmpl` fetches the age key from 1Password
8. Age-encrypted SSH keys get decrypted; all dotfiles applied

**Stage 3 — macOS defaults** ([`macos-defaults.sh`](./macos-defaults.sh))
- Faster keyboard repeat, screenshot location, Finder, Dock, trackpad

## Security model

| Asset | Where it lives | Protected by |
|---|---|---|
| App list, scripts | This public repo | Nothing — there's nothing to protect |
| SSH private keys | Private dotfiles repo | age encryption (key is in 1Password) |
| Age key | 1Password + `~/.config/age/chezmoi.txt` (mode 600) | 1Password master password + FileVault |
| GitHub auth | macOS Keychain | Keychain + Touch ID |
| VM mode (guest) | Brewfile + scripts gate on `is_vm` | No 1Password, no Logi Options+, no work credentials installed — guest stays disposable |

The chain of trust collapses to **one** thing: your 1Password master password.
Lose that, lose everything; keep that and even a full leak of the private repo only leaks encrypted blobs.

## Forking

This is *my* setup; it's not configurable. To use it for yourself:

1. Fork this repo.
2. Edit [`Brewfile`](./Brewfile) to your apps.
3. In [`bootstrap.sh`](./bootstrap.sh), change `REPO_OWNER` and `DOTFILES_USER` to your GitHub handle.
4. Make sure your dotfiles repo works with `chezmoi init --apply <your-user>`.
5. Update the curl URL in your fork's README.

## Manual steps after the script

The script can't sign you in to apps. After it finishes:

- iCloud (System Settings)
- 1Password (sign in once; then `op signin` for the CLI)
- Setapp, Alfred 5 (license keys are in 1Password)
- JetBrains Toolbox (then install IntelliJ/RubyMine/WebStorm from inside it)
- Moom (set trigger key + grid)
- VS Code (turn on Settings Sync)
- iTerm: import the [Dracula theme](https://draculatheme.com/iterm/), set as default profile
- Alfred: set clipboard history shortcut, swap Spotlight binding
- Old machine teardown: see `MERGE-OTHER-SERVERS.md` in dotfiles repo

## Files

| File | Purpose |
|---|---|
| `bootstrap.sh` | The main script (curl-piped) |
| `Brewfile` | Declarative app list (`brew bundle`) |
| `macos-defaults.sh` | macOS preference tweaks |

## Logs

Each run writes to `/tmp/install-mac-YYYYMMDD-HHMMSS.log`.

## Re-running

The whole script is idempotent. Re-run it any time to:

- Apply new entries you added to `Brewfile`
- Pull dotfiles updates (`chezmoi update --apply` runs in stage 2)
- Re-apply macOS defaults
