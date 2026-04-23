# Brewfile - jiang925's personal Mac stack
# https://github.com/jiang925/install-mac
#
# Apply:  brew bundle --file=Brewfile
# Add an app:  edit, commit, re-run.
# Find a mas id:  mas search "App Name"

# --- Bootstrap-essential ----------------------------------------------------
brew "gh"                # GitHub CLI - device-flow auth + private repo clone
brew "chezmoi"           # dotfiles manager
brew "mas"               # Mac App Store CLI
brew "age"               # used by chezmoi to encrypt secrets
cask "1password-cli"     # `op` — fetches the age key from 1Password

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
brew "openjdk"           # JDK/JRE - replaces the old StackOverflow JavaFX recipe

# --- Productivity (casks) ---------------------------------------------------
cask "google-chrome"
cask "iterm2"
cask "obsidian"
cask "1password"
cask "alfred"
cask "dropbox"
cask "setapp"
cask "logi-options-plus" # replaces older "Logitech Options"

# --- Dev (casks) ------------------------------------------------------------
cask "visual-studio-code"
cask "jetbrains-toolbox" # one installer for IntelliJ/RubyMine/WebStorm
cask "sourcetree"

# --- Mac utilities (casks) --------------------------------------------------
cask "flux-app"          # f.lux screen warmth
cask "imazing"

# --- Mac App Store ----------------------------------------------------------
mas "Moom",        id: 419330170
mas "iStat Menus", id: 1319778037
mas "WeChat",      id: 836500024
