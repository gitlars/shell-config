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
unset _shell_dir
