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
  return true if `sysctl -n kern.hv_vmm_present 2>/dev/null`.strip == "1"
  model = `sysctl -n hw.model 2>/dev/null`.force_encoding("BINARY").strip
  return true if model.match?(/VirtualMac|VMware|Parallels|VirtualBox|QEMU/)
  return true if `sysctl -n machdep.cpu.brand_string 2>/dev/null`.force_encoding("BINARY").match?(/QEMU|Virtual/i)
  # ioreg's output is not always valid UTF-8, so force binary before regex match.
  return true if `ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null`.force_encoding("BINARY").match?(/Virtual|Parallels|VMware/i)
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

# --- Dev (casks) ------------------------------------------------------------
cask "visual-studio-code"

# --- Mac utilities (casks) --------------------------------------------------
cask "flux-app"          # f.lux screen warmth

# --- Physical-Mac-only ------------------------------------------------------
# Skipped on VMs to keep guests Apple-ID-free (mas requires App Store sign-in,
# which makes the VM a 2FA endpoint and ties it to iCloud / payment / Find My
# — bad combo with experimental or untrusted workloads).
unless is_vm
  cask "1password"
  cask "1password-cli"
  cask "logi-options-plus" # replaces older "Logitech Options"
  cask "setapp"            # devmate.com CDN often unreachable from VMs
  mas "Moom",        id: 419330170
  mas "iStat Menus", id: 1319778037
  mas "WeChat",      id: 836500024
end
