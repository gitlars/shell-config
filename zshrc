# ~/.config/shell/zshrc
#
# zsh-specific configuration. Everything portable between zsh and bash lives in
# common.sh, which this file sources at the end -- the completion system has to
# be up before fzf's key bindings load.

# --- completion --------------------------------------------------------------
# macOS never runs compinit for you, and without it there is no completion
# system at all: no directory completion for `cd`, no git subcommands, no ssh
# hosts, no command flags.
#
# compinit's security audit is the slowest thing in a typical zsh startup, so
# cache the dump and only re-audit once a day.
_zdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zdump:h}"
autoload -Uz compinit
if [[ ! -e $_zdump ]] || [[ -n $(find "$_zdump" -mtime +1 2>/dev/null) ]]; then
  compinit -d "$_zdump"
else
  compinit -C -d "$_zdump"
fi
unset _zdump

# Case-insensitive, then partial-word matching: `cd dow<TAB>` finds Downloads,
# and `cd u/l/b<TAB>` expands to /usr/local/bin.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Cache slow completions (apt, brew, ...) rather than recomputing them.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# --- directories -------------------------------------------------------------
# cd keeps a stack, so `cd -<TAB>` lists where you have been. AUTO_CD is
# deliberately left off: it makes a bare directory name change directory, which
# surprises people when a directory shares a name with a command.
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# --- history -----------------------------------------------------------------
# Space-prefixed commands stay out of history -- useful for anything carrying a
# secret. Set here as well as in your ~/.zshrc so it travels with the repo.
setopt HIST_IGNORE_SPACE
HISTSIZE=50000
SAVEHIST=50000

# --- shared ------------------------------------------------------------------
_shell_dir="${0:A:h}"
[ -r "$_shell_dir/common.sh" ] && . "$_shell_dir/common.sh"

# --- plugins -----------------------------------------------------------------
# ORDER MATTERS, and getting it wrong fails quietly:
#   fzf-tab      after compinit *and* after common.sh, because fzf's own
#                completion binds TAB and whichever loads last wins
#   autosuggest  after fzf-tab
#   syntax-hl    LAST of all -- it wraps every ZLE widget defined before it, so
#                anything loaded afterwards is left unhighlighted
#
# Each is optional; a machine without them just gets a plainer shell.

_brew="${HOMEBREW_PREFIX:-/opt/homebrew}"

# Source the first readable path from the list.
_zplug() {
  local f
  for f in "$@"; do
    if [[ -r $f ]]; then source "$f"; return 0; fi
  done
  return 1
}

# fzf-tab: TAB becomes a fuzzy picker with a preview pane.
if _zplug \
  "$_brew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" \
  /usr/share/zsh/plugins/fzf-tab/fzf-tab.zsh \
  "$_shell_dir/plugins/fzf-tab/fzf-tab.zsh"
then
  # fzf-tab supplies its own menu; zsh's built-in one fights it.
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:*' fzf-flags --height=45% --layout=reverse --border --info=inline
  # Preview the directory you are about to cd into.
  if command -v eza >/dev/null 2>&1; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath'
  else
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 $realpath'
  fi
fi

# zsh-autosuggestions: grey ghost text from history; -> accepts it.
if _zplug \
  "$_brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
then
  # History first, then the completion system when history has nothing.
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  # fg=8 is ANSI bright-black: dim in every palette, no truecolor needed.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
fi

# zsh-syntax-highlighting: commands go green when valid, red when not. LAST.
if [[ -d "$_brew/share/zsh-syntax-highlighting/highlighters" ]]; then
  export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR="$_brew/share/zsh-syntax-highlighting/highlighters"
fi
_zplug \
  "$_brew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

unfunction _zplug
unset _brew _shell_dir
