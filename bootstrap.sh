#!/usr/bin/env bash
# install-mac/bootstrap.sh
# Zero-to-set-up Mac in one curl-pipe.
# Personal install script for jiang925. Fork & edit the Brewfile to make your own.
#
# Run:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiang925/install-mac/main/bootstrap.sh)"
#
# Pin to a known-good commit (recommended after first install):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiang925/install-mac/<sha>/bootstrap.sh)"

set -euo pipefail

# --- Config -----------------------------------------------------------------
readonly REPO_OWNER="jiang925"
readonly REPO_NAME="install-mac"
readonly REPO_BRANCH="${INSTALL_MAC_BRANCH:-main}"
readonly DOTFILES_USER="jiang925"
readonly RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"
readonly LOG_FILE="${TMPDIR:-/tmp}/install-mac-$(date +%Y%m%d-%H%M%S).log"

HOMEBREW_PREFIX=""
IS_VM=0

# --- Logging ----------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''
fi

log()      { printf '%s[%s]%s %s\n' "$C_DIM" "$(date +%H:%M:%S)" "$C_RESET" "$*" | tee -a "$LOG_FILE"; }
info()     { printf '%s%s==>%s %s%s%s\n' "$C_BLUE" "$C_BOLD" "$C_RESET" "$C_BOLD" "$*" "$C_RESET" | tee -a "$LOG_FILE"; }
success()  { printf '%s\xe2\x9c\x93%s %s\n' "$C_GREEN" "$C_RESET" "$*" | tee -a "$LOG_FILE"; }
warn()     { printf '%s\xe2\x9a\xa0%s  %s\n' "$C_YELLOW" "$C_RESET" "$*" | tee -a "$LOG_FILE"; }
err()      { printf '%s\xe2\x9c\x97%s  %s\n' "$C_RED" "$C_RESET" "$*" | tee -a "$LOG_FILE" >&2; }
die()      { err "$*"; exit 1; }
step()     { printf '\n%s%s\xe2\x94\x81\xe2\x94\x81 %s \xe2\x94\x81\xe2\x94\x81%s\n' "$C_BOLD" "$C_BLUE" "$*" "$C_RESET" | tee -a "$LOG_FILE"; }

confirm() {
  local prompt="${1:-Continue?}"
  local response
  if [[ ! -t 0 ]]; then
    warn "No tty for prompt; defaulting to 'no' for: $prompt"
    return 1
  fi
  read -r -p "$(printf '%s? %s [y/N] %s' "$C_YELLOW" "$prompt" "$C_RESET")" response
  [[ "$response" =~ ^[Yy]$ ]]
}

# --- Prereqs ----------------------------------------------------------------
require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS only — got $(uname -s)."
}

detect_arch() {
  local arch; arch="$(uname -m)"
  case "$arch" in
    arm64)  HOMEBREW_PREFIX="/opt/homebrew" ;;
    x86_64) HOMEBREW_PREFIX="/usr/local" ;;
    *) die "Unsupported architecture: $arch" ;;
  esac
  log "Architecture: $arch — Homebrew prefix: $HOMEBREW_PREFIX"
}

is_vm() {
  # 1. Apple's official "I am running as a guest" sysctl (Apple-VZ, Parallels, VMware Fusion on Apple Silicon)
  [[ "$(sysctl -n kern.hv_vmm_present 2>/dev/null)" == "1" ]] && return 0
  # 2. Model-string fallback (UTM/QEMU and older hypervisors)
  local model
  model="$(sysctl -n hw.model 2>/dev/null || true)"
  [[ "$model" =~ ^(VirtualMac|VMware|Parallels|VirtualBox|QEMU) ]] && return 0
  # 3. CPU brand fallback (Intel UTM/QEMU)
  sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -qi 'qemu\|virtual' && return 0
  # 4. IORegistry fallback (catch-all)
  ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null | grep -qi 'virtual\|parallels\|vmware' && return 0
  return 1
}

require_network() {
  curl --silent --head --fail --max-time 5 https://github.com >/dev/null \
    || die "No network connectivity to github.com"
}

keep_sudo_alive() {
  info "Acquiring sudo (cached for the session)"
  sudo -v || die "sudo authentication failed"
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

# --- Steps ------------------------------------------------------------------
install_xcode_clt() {
  step "Xcode Command Line Tools"
  if xcode-select -p &>/dev/null; then
    success "CLT already installed at $(xcode-select -p)"
    return
  fi
  info "Triggering xcode-select --install (a GUI dialog will appear)"
  xcode-select --install || true
  warn "Click 'Install' in the dialog, then wait. Polling..."
  until xcode-select -p &>/dev/null; do sleep 5; done
  success "CLT installed at $(xcode-select -p)"
}

install_homebrew() {
  step "Homebrew"
  if command -v brew &>/dev/null; then
    success "Homebrew already installed: $(brew --version | head -1)"
  else
    info "Installing Homebrew (non-interactive)"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
  success "Homebrew on PATH: $(brew --version | head -1)"
}

run_brew_bundle() {
  step "Brewfile (CLI + casks + mas)"
  local brewfile="${TMPDIR:-/tmp}/Brewfile.public"
  info "Fetching Brewfile from ${RAW_URL}/Brewfile"
  curl -fsSL "${RAW_URL}/Brewfile" -o "$brewfile"
  info "Running brew bundle (this takes a while)"
  # NOTE: --no-lock was removed when Homebrew dropped Brewfile.lock.json (~2024).
  brew bundle --file="$brewfile"
  success "Brewfile applied"
}

install_terminal_config() {
  step "Terminal config (ghostty / cmux)"
  local cfg_dir="${HOME}/.config/ghostty"
  local app_dir="${HOME}/Library/Application Support/com.mitchellh.ghostty"
  mkdir -p "$cfg_dir" "$app_dir"
  info "Fetching ghostty config from ${RAW_URL}/configs/ghostty.config"
  curl -fsSL "${RAW_URL}/configs/ghostty.config" -o "${cfg_dir}/config"
  cp "${cfg_dir}/config" "${app_dir}/config.ghostty"
  success "Ghostty config installed (read by both ghostty and cmux)"
}

install_omz() {
  step "Oh My Zsh + powerlevel10k + zsh-autosuggestions"
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    success "OMZ already installed"
  else
    info "Installing Oh My Zsh (KEEP_ZSHRC=yes — won't touch ~/.zshrc)"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  local custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
  if [[ ! -d "${custom}/themes/powerlevel10k" ]]; then
    info "Cloning powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${custom}/themes/powerlevel10k"
  fi
  if [[ ! -d "${custom}/plugins/zsh-autosuggestions" ]]; then
    info "Cloning zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${custom}/plugins/zsh-autosuggestions"
  fi
  success "OMZ + p10k + autosuggestions ready"
}

github_auth() {
  step "GitHub auth (for private dotfiles clone)"
  if gh auth status &>/dev/null; then
    success "Already authenticated as $(gh api user --jq .login)"
  else
    info "Starting gh login (opens a browser for OAuth)"
    gh auth login --hostname github.com --git-protocol https --web
  fi
  info "Configuring git to use gh as credential helper"
  gh auth setup-git
}

run_chezmoi() {
  step "chezmoi (private dotfiles)"
  if [[ -d "${HOME}/.local/share/chezmoi/.git" ]]; then
    info "chezmoi already initialized — running 'chezmoi update'"
    chezmoi update --apply
  else
    info "Initializing chezmoi from github.com/${DOTFILES_USER}/dotfiles"
    chezmoi init --apply "$DOTFILES_USER"
  fi
  success "chezmoi applied"
}

apply_macos_defaults() {
  step "macOS defaults"
  local script_url="${RAW_URL}/macos-defaults.sh"
  if curl --silent --head --fail "$script_url" >/dev/null; then
    info "Applying $script_url"
    bash <(curl -fsSL "$script_url")
  else
    warn "No macos-defaults.sh found at $script_url — skipping"
  fi
}

# --- Main -------------------------------------------------------------------
main() {
  printf '%s%s\n' "$C_BOLD" "$C_BLUE"
  cat <<'BANNER'
  ===============================================
   install-mac  |  bootstrap a fresh Mac
  ===============================================
BANNER
  printf '%s' "$C_RESET"

  log "Log file: $LOG_FILE"
  require_macos
  detect_arch
  if is_vm; then
    warn "VM detected (hw.model=$(sysctl -n hw.model)) — sensitive apps will be skipped"
    IS_VM=1
  else
    IS_VM=0
  fi
  require_network

  if ! confirm "Begin bootstrap? (sudo will be requested)"; then
    die "Aborted by user."
  fi

  keep_sudo_alive

  install_xcode_clt
  install_homebrew
  run_brew_bundle
  install_terminal_config
  install_omz
  github_auth
  run_chezmoi
  apply_macos_defaults

  printf '\n%s%s---------------------------------------------%s\n' "$C_GREEN" "$C_BOLD" "$C_RESET"
  success "Bootstrap complete. Log: $LOG_FILE"
  printf '%s%s---------------------------------------------%s\n\n' "$C_GREEN" "$C_BOLD" "$C_RESET"

  cat <<'NEXT'
Next steps (manual, can't be scripted):
  - Sign in: iCloud, Setapp, Alfred (license in 1Password)
  - VS Code: turn on Settings Sync
  - Alfred: set clipboard history shortcut, swap Spotlight binding
  - Moom: set trigger key + grid
  - cmux: pin to dock; theme already set via configs/ghostty.config
  - Open a new terminal so the new zshrc loads
  - Verify SSH: ssh -T git@github.com
  - Verify dotfiles: ls -la ~/.ssh
NEXT
}

main "$@"
