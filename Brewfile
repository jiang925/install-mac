# Brewfile - jiang925's personal Mac stack
# https://github.com/jiang925/install-mac
#
# Apply:  brew bundle --file=Brewfile
# Add an app:  edit, commit, re-run.
# Find a mas id:  mas search "App Name"

# Physical-Mac-only apps. On VMs, 1Password and Logitech hardware aren't
# relevant; remote access from host. Brewfile is a Ruby DSL, so we can
# detect VM at evaluation time and skip those casks accordingly.
def is_vm
  model = `sysctl -n hw.model 2>/dev/null`.force_encoding("BINARY").strip
  return true if model.match?(/VMware|Parallels|VirtualMachine|VirtualBox|QEMU/)
  # ioreg's output is not always valid UTF-8, so force binary before regex match.
  return true if `ioreg -l 2>/dev/null`.force_encoding("BINARY").match?(/VirtualMachine/)
  false
end

# --- Bootstrap-essential ----------------------------------------------------
brew "gh"                # GitHub CLI - device-flow auth + private repo clone
brew "chezmoi"           # dotfiles manager
brew "mas"               # Mac App Store CLI
brew "age"               # used by chezmoi to encrypt secrets

# --- Core CLI ---------------------------------------------------------------
brew "coreutils"
brew "git"
brew "htop"
brew "iperf3"
brew "jq"
brew "nmap"
brew "rsync"
brew "ssh-copy-id"
brew "tree"
brew "wakeonlan"
brew "wget"
brew "sevenzip"
brew "fswatch"           # used by ai-file-daemon

# --- Languages / runtimes ---------------------------------------------------
brew "pyenv"
brew "pyenv-virtualenv"
brew "rbenv"
brew "ruby"

# --- Productivity (casks) ---------------------------------------------------
cask "google-chrome"
cask "cmux"           # Ghostty-based terminal with vertical tabs
cask "obsidian"
cask "alfred"
cask "dropbox"
cask "setapp"

# --- Dev (casks) ------------------------------------------------------------
cask "visual-studio-code"

# --- Mac utilities (casks) --------------------------------------------------
cask "flux-app"          # f.lux screen warmth

# --- Mac App Store ----------------------------------------------------------
mas "Moom",        id: 419330170
mas "iStat Menus", id: 1319778037
mas "WeChat",      id: 836500024

# --- Physical-Mac-only ------------------------------------------------------
unless is_vm
  cask "1password"
  cask "1password-cli"
  cask "logi-options-plus" # replaces older "Logitech Options"
end
