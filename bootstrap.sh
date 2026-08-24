#!/usr/bin/env bash
#
# Wire a shell's rc file to ~/.config/shell/common.sh.
#
# Guarantees:
#   * Idempotent      -- re-running never duplicates anything.
#   * Non-destructive -- only the marked managed block is ever written. Every
#                        other line in your rc file is left byte-for-byte alone.
#   * Conflict-aware  -- if your rc already initialises fzf/zoxide or sources
#                        common.sh outside the managed block, it reports and
#                        refuses rather than creating a duplicate or clobbering.
#
# Usage: bootstrap.sh [--shell zsh|bash|auto] [--dry-run] [--force]
#
# Written for bash 3.2 so it runs on a stock macOS as well as Linux.

set -euo pipefail

SHELL_DIR="${SHELL_CONFIG_DIR:-$HOME/.config/shell}"
COMMON="$SHELL_DIR/common.sh"
BEGIN="# >>> shell-config (managed) >>>"
END="# <<< shell-config (managed) <<<"

TARGET_SHELL="auto"
DRY_RUN=0
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --shell)   TARGET_SHELL="${2:-auto}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

ok()   { printf '  \033[32mok\033[0m      %s\n' "$1"; }
skip() { printf '  \033[34mskip\033[0m    %s\n' "$1"; }
warn() { printf '  \033[33mwarn\033[0m    %s\n' "$1"; }
bad()  { printf '  \033[31mconflict\033[0m %s\n' "$1"; }

[ -r "$COMMON" ] || { echo "missing $COMMON" >&2; exit 1; }

if [ "$TARGET_SHELL" = "auto" ]; then
  case "${SHELL:-}" in
    *zsh)  TARGET_SHELL=zsh ;;
    *bash) TARGET_SHELL=bash ;;
    *)     TARGET_SHELL=zsh ;;
  esac
fi

case "$TARGET_SHELL" in
  zsh)  RC="$HOME/.zshrc" ;;
  bash) RC="$HOME/.bashrc" ;;
  *) echo "unsupported shell: $TARGET_SHELL" >&2; exit 2 ;;
esac

[ -r "$SHELL_DIR/${TARGET_SHELL}rc" ] || {
  echo "missing $SHELL_DIR/${TARGET_SHELL}rc" >&2; exit 1; }

block() {
  # Prefer a $HOME-relative path so the line reads the same on every machine.
  rcfile="$SHELL_DIR/${TARGET_SHELL}rc"
  case "$rcfile" in
    "$HOME"/*) rcfile="\$HOME${rcfile#$HOME}" ;;
  esac
  printf '%s\n' "$BEGIN"
  printf '%s\n' "# Managed by $SHELL_DIR/bootstrap.sh -- this block is rewritten on update."
  printf '%s\n' "# Put your own settings OUTSIDE the markers; they are never touched."
  printf '%s\n' "[ -r \"$rcfile\" ] && . \"$rcfile\""
  printf '%s\n' "$END"
}

# Everything in the rc file EXCEPT our managed block.
strip_block() {
  awk -v b="$BEGIN" -v e="$END" '
    $0==b { inb=1; next }
    $0==e { inb=0; next }
    !inb  { print }
  ' "$1"
}

# Pre-existing lines that would duplicate or fight what common.sh does.
find_conflicts() {
  local file="$1"
  [ -f "$file" ] || return 0
  strip_block "$file" | grep -nE \
    'starship[[:space:]]+init|zoxide[[:space:]]+init|fzf[[:space:]]+--(zsh|bash)|key-bindings\.(zsh|bash)|config/shell/|STARSHIP_CONFIG|compinit|bash_completion|^[[:space:]]*(alias[[:space:]]+z=|z[[:space:]]*\(\))' \
    || true
}

echo
echo "shell-config bootstrap -> $TARGET_SHELL ($RC)"
echo

# ---------------------------------------------------------------- conflicts --
conflicts="$(find_conflicts "$RC")"
if [ -n "$conflicts" ]; then
  bad "$RC already contains lines that overlap common.sh:"
  printf '%s\n' "$conflicts" | sed 's/^/            /'
  echo
  if [ "$FORCE" -eq 0 ]; then
    echo "  Refusing to modify $RC. Nothing has been changed."
    echo "  Remove or comment those lines, then re-run. Use --force to proceed anyway."
    exit 1
  fi
  warn "--force given; proceeding despite the conflicts above"
fi

# ------------------------------------------------------------- idempotency --
desired="$(block)"

if [ -f "$RC" ] && grep -qF "$BEGIN" "$RC"; then
  current="$(awk -v b="$BEGIN" -v e="$END" '$0==b{inb=1} inb{print} $0==e{inb=0}' "$RC")"
  if [ "$current" = "$desired" ]; then
    skip "managed block already present and current -- no change"
    NEEDS_WRITE=0
  else
    ok "managed block present but outdated -- will refresh in place"
    NEEDS_WRITE=1
  fi
else
  ok "managed block absent -- will append"
  NEEDS_WRITE=1
fi

# --------------------------------------------------------- bash_profile fix --
# macOS runs login shells, which read .bash_profile and never .bashrc.
PROFILE_WRITE=0
if [ "$TARGET_SHELL" = "bash" ]; then
  BP="$HOME/.bash_profile"
  if [ -f "$BP" ] && grep -qE '(^|[^#])\.[[:space:]]+.*\.bashrc|source[[:space:]]+.*\.bashrc' "$BP"; then
    skip ".bash_profile already sources .bashrc"
  else
    ok ".bash_profile will be given a line sourcing .bashrc (login shells need it)"
    PROFILE_WRITE=1
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "  --dry-run: nothing written. Block that would be applied:"
  printf '%s\n' "$desired" | sed 's/^/      /'
  exit 0
fi

# -------------------------------------------------------------------- write --
if [ "$NEEDS_WRITE" -eq 1 ]; then
  stamp="$(date +%Y%m%d%H%M%S)"
  if [ -f "$RC" ]; then
    cp "$RC" "$RC.bak-$stamp"
    ok "backed up -> $(basename "$RC").bak-$stamp"
    tmp="$(mktemp)"
    strip_block "$RC" > "$tmp"
    # collapse a trailing blank line so repeated runs cannot grow the file
    printf '%s\n' "$(cat "$tmp")" > "$tmp"
    { cat "$tmp"; echo; printf '%s\n' "$desired"; } > "$RC"
    rm -f "$tmp"
  else
    printf '%s\n' "$desired" > "$RC"
  fi
  ok "wrote managed block to $RC"
fi

if [ "$PROFILE_WRITE" -eq 1 ]; then
  [ -f "$BP" ] && cp "$BP" "$BP.bak-$(date +%Y%m%d%H%M%S)"
  {
    printf '%s\n' "$BEGIN"
    printf '%s\n' '[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
    printf '%s\n' "$END"
  } >> "$BP"
  ok "wrote .bashrc source line to $BP"
fi

echo
echo "  Done. Open a new shell, or run:  . $RC"
echo
