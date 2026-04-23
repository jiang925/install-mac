# install-mac/zsh/zshrc.public.zsh
# Framework-only zsh config — sourced by chezmoi-managed ~/.zshrc.
# https://github.com/jiang925/install-mac
#
# What lives here:
#   - Oh My Zsh + powerlevel10k + plugins (theme, prompt, completion)
#   - Lazy-loaders for pyenv / goenv (PATH-only at startup; eval on first call)
#   - Ruby (Homebrew) on PATH
#
# What does NOT live here:
#   - Personal secrets (none currently)
#   - Work-only env (work-specific tools and aliases) → ~/.zshrc.work
#   - MDM-injected blocks (your company's MDM shell-profile) → not in this repo

# Skip in non-interactive shells
[[ $- != *i* ]] && return

# --- powerlevel10k instant prompt -------------------------------------------
# Must stay near the top. Anything that needs console input (passwords, [y/n])
# goes ABOVE this block; everything else goes below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt: `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Oh My Zsh --------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(history)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=1

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor root line)
ZSH_HIGHLIGHT_PATTERNS=('rm -rf *' 'fg=white,bold,bg=red')

plugins=(
  git
  macos
  z
  zsh-autosuggestions
  history-substring-search
)

source "$ZSH/oh-my-zsh.sh"

# --- Languages --------------------------------------------------------------
# Homebrew Ruby (override system Ruby)
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# pyenv — PATH only at startup; full init on first invocation
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  pyenv "$@"
}

# goenv — same pattern
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
goenv() {
  unfunction goenv
  eval "$(command goenv init -)"
  goenv "$@"
}
