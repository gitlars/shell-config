# ~/.config/shell/common.sh
#
# Shared shell configuration, sourced by both zsh and bash. Keep everything in
# here portable between the two: no `setopt`, no `bindkey`, no `shopt`. Anything
# shell-specific belongs in the per-shell rc file, not this one.

# Which shell is running? Several tools need a per-shell init snippet.
if [ -n "${ZSH_VERSION:-}" ]; then
  _shell_name=zsh
elif [ -n "${BASH_VERSION:-}" ]; then
  _shell_name=bash
else
  _shell_name=
fi

# Where this file lives, so the repo can be cloned anywhere rather than being
# pinned to ~/.config/shell. zsh sets $0 to the sourced path; bash needs
# BASH_SOURCE because $0 is the shell name.
if [ -n "${ZSH_VERSION:-}" ]; then
  _shell_src="$0"
else
  _shell_src="${BASH_SOURCE[0]:-$0}"
fi
_shell_dir="$(CDPATH= cd -- "$(dirname -- "$_shell_src")" 2>/dev/null && pwd)"

# --- starship ---------------------------------------------------------------
# Prompt: directory, git branch + dirty state, mid-rebase warnings, exit code,
# and command duration for anything slow. One config for every shell and OS.
if [ -n "$_shell_name" ] && command -v starship >/dev/null 2>&1; then
  # Respect an existing STARSHIP_CONFIG; otherwise use the one beside this file.
  if [ -z "${STARSHIP_CONFIG:-}" ] && [ -r "$_shell_dir/starship.toml" ]; then
    export STARSHIP_CONFIG="$_shell_dir/starship.toml"
  fi
  eval "$(starship init "$_shell_name")"
fi

# --- zoxide -----------------------------------------------------------------
# `z <fragment>` jumps to a directory you have visited before, ranked by how
# often and how recently. `zi` picks interactively. Needs a week of normal use
# before it starts feeling useful.
if [ -n "$_shell_name" ] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$_shell_name")"
fi

# --- fzf --------------------------------------------------------------------
# CTRL+R  fuzzy history search        (the big one)
# CTRL+T  insert a file path at the cursor
# ALT+C   cd into a subdirectory
#
# fzf 0.48+ ships its own init via `fzf --zsh` / `fzf --bash`. Older distro
# packages (Ubuntu 22.04 ships 0.29) install shell snippets on disk instead, so
# fall back to those.
if [ -n "$_shell_name" ] && command -v fzf >/dev/null 2>&1; then
  if fzf "--$_shell_name" >/dev/null 2>&1; then
    eval "$(fzf "--$_shell_name")"
  else
    for _fzf_dir in /usr/share/doc/fzf/examples /usr/share/fzf "$HOME/.fzf/shell"; do
      [ -f "$_fzf_dir/key-bindings.$_shell_name" ] && . "$_fzf_dir/key-bindings.$_shell_name"
      [ -f "$_fzf_dir/completion.$_shell_name" ] && . "$_fzf_dir/completion.$_shell_name"
    done
    unset _fzf_dir
  fi
fi

# --- Debian/Ubuntu binary names ---------------------------------------------
# Debian ships bat as `batcat` and fd as `fdfind`, because both names were
# already taken by other packages. Normalise to one name so muscle memory and
# the rest of this file work identically on every distro.
if command -v fd >/dev/null 2>&1; then
  _fd=fd
elif command -v fdfind >/dev/null 2>&1; then
  _fd=fdfind
  alias fd=fdfind
else
  _fd=
fi

if command -v bat >/dev/null 2>&1; then
  _bat=bat
elif command -v batcat >/dev/null 2>&1; then
  _bat=batcat
  alias bat=batcat
else
  _bat=
fi

# --- eza --------------------------------------------------------------------
# Aliases apply to interactive use only; scripts calling `ls` are unaffected,
# and `command ls` or `\ls` always reaches the real binary.
#
# GOTCHA: eza's -h is --header, not ls's --human-readable. eza prints human
# sizes by default, so `ls -lh` still shows what you wanted -- plus a header.
if command -v eza >/dev/null 2>&1; then
  # icons=auto keeps icons out of pipes; they need a Nerd Font to render.
  _eza='eza --group-directories-first --icons=auto'
  alias ls="$_eza"
  alias l="$_eza --oneline"
  alias ll="$_eza --long --git --header --time-style=long-iso"
  alias la="$_eza --long --git --header --time-style=long-iso --all"
  alias lt="$_eza --tree --level=2"
  alias lta="$_eza --tree --level=2 --all --ignore-glob=.git"
  unset _eza
fi

# --- bat --------------------------------------------------------------------
# `cat` is deliberately NOT aliased. It is a POSIX tool that people reason about
# as behaving exactly one way, and quietly changing it invites surprises in
# pipelines and pasted commands. Reach for `bat` when you want highlighting.
if [ -n "$_bat" ]; then
  # `ansi` follows the terminal's own palette, so bat matches whatever colour
  # scheme is active instead of fighting it. `bat --list-themes` to change.
  export BAT_THEME="${BAT_THEME:-ansi}"
  export BAT_STYLE="${BAT_STYLE:-numbers,changes,header}"

  # Syntax-highlighted man pages. MANROFFOPT=-c is needed for groff 1.23+,
  # which otherwise emits escapes that survive `col` and litter the output.
  export MANPAGER="sh -c 'col -bx | $_bat --language=man --style=plain'"
  export MANROFFOPT='-c'

  # `bathelp fd` pages a long --help through bat. Deliberately not named
  # `help`: that is a bash builtin, and shadowing it would break `help while`.
  bathelp() {
    local _b
    _b=$(command -v bat 2>/dev/null || command -v batcat 2>/dev/null) || return 1
    "$@" --help 2>&1 | "$_b" --language=help --style=plain
  }
fi

# --- fd ---------------------------------------------------------------------
# fd respects .gitignore and skips dotfiles by default, which is right almost
# always. `fda` is the escape hatch for the times it is not.
if [ -n "$_fd" ]; then
  alias fda="$_fd --hidden --no-ignore"
fi

# --- ripgrep ----------------------------------------------------------------
if command -v rg >/dev/null 2>&1 && [ -r "$_shell_dir/ripgreprc" ]; then
  export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$_shell_dir/ripgreprc}"
fi

# --- fzf, backed by fd ------------------------------------------------------
# Makes CTRL+T and ALT+C respect .gitignore and skip .git, and much faster than
# the default find-based walk.
if [ -n "$_fd" ]; then
  export FZF_DEFAULT_COMMAND="$_fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_fd --type d --hidden --follow --exclude .git"
fi

# Tokyo Night colours, matching the WezTerm scheme and the starship prompt.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40% --layout=reverse --border --info=inline \
--color=fg:#c0caf5,hl:#7aa2f7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff \
--color=info:#565f89,prompt:#9ece6a,pointer:#bb9af7,marker:#e0af68,spinner:#bb9af7,header:#565f89}"

unset _shell_name _shell_src _shell_dir _fd _bat
