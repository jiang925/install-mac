#!/usr/bin/env bash
# install-mac/macos-defaults.sh
# Sane macOS defaults for jiang925.
# Source: https://github.com/jiang925/install-mac
#
# Run standalone:  bash macos-defaults.sh
# (also auto-invoked at the end of bootstrap.sh)

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "macOS only."; exit 1; }

is_vm() {
  local model
  model="$(sysctl -n hw.model 2>/dev/null || true)"
  if [[ "$model" =~ ^(VMware|Parallels|VirtualMachine|VirtualBox|QEMU) ]]; then
    return 0
  fi
  if ioreg -l 2>/dev/null | grep -qi 'VirtualMachine'; then
    return 0
  fi
  return 1
}

echo "==> Applying macOS defaults"

# --- Keyboard ---------------------------------------------------------------
# Faster key repeat (Settings UI minimum is 15; 1 is faster than that)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold accent popover so key-repeat works in all apps
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# --- Finder -----------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# --- Screenshots ------------------------------------------------------------
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# --- Dock -------------------------------------------------------------------
if ! is_vm; then
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock minimize-to-application -bool true
else
  echo "  dock: skipped on VM"
fi

# --- Trackpad ---------------------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --- Safety net -------------------------------------------------------------
# Disable the "Are you sure you want to open this app?" dialog every time
defaults write com.apple.LaunchServices LSQuarantine -bool false

# --- git speedups (per Install computer.md) --------------------------------
if command -v git >/dev/null 2>&1; then
  git config --global core.fsmonitor true
  git config --global core.untrackedCache true
  echo "  git: fsmonitor + untrackedCache enabled"
fi

# --- Restart affected services ---------------------------------------------
killall Finder Dock SystemUIServer cfprefsd 2>/dev/null || true

echo "OK macOS defaults applied. Some changes require logout to take effect."
