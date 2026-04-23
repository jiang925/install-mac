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
5. Install Oh My Zsh + `powerlevel10k` theme + `zsh-autosuggestions` plugin (`KEEP_ZSHRC=yes` so chezmoi can own `~/.zshrc`)
6. `gh auth login --web` — opens a browser for OAuth, token lands in macOS Keychain
7. `gh auth setup-git` — git uses the gh token for HTTPS clones

Both `bootstrap.sh` and `macos-defaults.sh` detect VMs (VMware/Parallels/VirtualBox/QEMU) via `sysctl hw.model` + `ioreg`. On VMs the following are skipped: `1password`, `1password-cli`, `logi-options-plus`, and the Dock autohide tweaks — they're either irrelevant on a guest or better handled from the host.

**Stage 2 — private, handed off to chezmoi**
6. `chezmoi init --apply jiang925` — clones the private dotfiles repo
7. chezmoi's `run_once_before_01-setup-1password.sh.tmpl` fetches the age key from 1Password
8. Age-encrypted SSH keys get decrypted; all dotfiles applied
9. `~/.zshrc` is rewritten by chezmoi's `modify_dot_zshrc` upsert (see *Zsh layout* below)

**Stage 3 — macOS defaults** ([`macos-defaults.sh`](./macos-defaults.sh))
- Faster keyboard repeat, screenshot location, Finder, Dock, trackpad

## Zsh layout

`~/.zshrc` is composed from three sources, all merged by chezmoi's `modify_dot_zshrc`
upsert script (in the dotfiles repo). The script idempotently maintains a single
marker block at the top of the file and passes everything else through verbatim,
so MDM-injected blocks (your company's MDM shell-profile blocks) and any hand-edits
survive every `chezmoi apply`.

```
~/.zshrc
├── # >>> chezmoi-managed >>>           ← injected by modify_dot_zshrc, idempotent
│   source ~/.config/zsh/public.zsh    ← pulled from THIS repo (zsh/zshrc.public.zsh)
│   source ~/.zshrc.work               ← exists only on work machines
├── # <<< chezmoi-managed <<<
├── ### BEGIN--Company MDM Shell ...     ← MDM, written by company script, preserved
├── # >>> company-tool setup ...              ← MDM, preserved
└── # tool init                          ← anything that depends on MDM PATH lives here
```

Three tiers of content:

| File | Lives where | Contents | Synced |
|---|---|---|---|
| [`zsh/zshrc.public.zsh`](./zsh/zshrc.public.zsh) | Public repo (this one) | OMZ + p10k + plugins + lazy-loaders (pyenv/goenv) + portable personal tooling | All machines, via chezmoi external |
| `~/.zshrc.work` | Hand-maintained, NOT in any repo | Work-only env (work-specific tools, credentials, language managers) | Manual; absent on personal/VM machines |
| MDM blocks in `~/.zshrc` | Injected by company scripts | MDM-managed shell-profile blocks | Managed by IT, untouched by chezmoi |

The same pattern (`modify_` + external) can hold for `~/.zprofile` later if needed.

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
- Moom (set trigger key + grid)
- VS Code (turn on Settings Sync)
- cmux: pin to dock; theme is already set via `configs/ghostty.config`
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
