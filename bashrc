# ~/.config/shell/bashrc
#
# bash-specific configuration. Everything portable between zsh and bash lives in
# common.sh, sourced at the end.

# --- completion --------------------------------------------------------------
# bash-completion is a separate package: `brew install bash-completion@2` on
# macOS, `apt install bash-completion` on Debian/Ubuntu.
if ! shopt -oq posix; then
  for _bc in /opt/homebrew/etc/profile.d/bash_completion.sh \
             /usr/local/etc/profile.d/bash_completion.sh \
             /usr/share/bash-completion/bash_completion \
             /etc/bash_completion; do
    if [ -r "$_bc" ]; then . "$_bc"; break; fi
  done
  unset _bc
fi

# --- history -----------------------------------------------------------------
# ignorespace is bash's equivalent of zsh's HIST_IGNORE_SPACE.
HISTCONTROL=ignorespace:erasedups
HISTSIZE=50000
HISTFILESIZE=50000
# Append rather than overwrite, so concurrent shells do not clobber each other.
shopt -s histappend

# Keep $LINES/$COLUMNS right after a resize. Not globstar: macOS ships bash 3.2,
# which predates it.
shopt -s checkwinsize cdspell

# --- shared ------------------------------------------------------------------
_shell_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -r "$_shell_dir/common.sh" ] && . "$_shell_dir/common.sh"
unset _shell_dir
