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

unset _shell_name _shell_src _shell_dir
