# shell-config

Shared shell configuration for zsh and bash. One set of tools and settings that
behaves the same on macOS (zsh) and Ubuntu (bash), without forcing either
platform off its default shell.

## Why not just pick one shell?

macOS defaults to zsh; Ubuntu defaults to bash. Converging on one means fighting
a vendor default on every machine — and on a server you do not control, bash is
what exists. So the substance is shared and only the thin per-shell glue differs.

Roughly 80% of a modern shell config ports cleanly:

| Shares cleanly | Needs a per-shell line |
|---|---|
| `PATH` and other exports | history options (`setopt` vs `HISTCONTROL`) |
| aliases | completion system (`compinit` vs `bash_completion`) |
| tool init (`fzf`, `zoxide`, `starship`) | key bindings (`bindkey` vs `bind`) |
| functions, if written POSIX-ish | |

`common.sh` holds the portable part. Anything shell-specific goes in `zshrc` or
`bashrc`, never in `common.sh`.

The sourcing chain is `~/.zshrc` → `zshrc` → `common.sh`. Order matters: the
completion system has to be initialised before fzf's key bindings load.

> **Scope note:** this covers zsh and bash only. Windows means PowerShell, where
> the rc file does not port — though every tool below has a native Windows build,
> and `starship.toml` works in PowerShell unchanged.

## Files

| Path | Purpose |
|---|---|
| `common.sh` | Portable config sourced by both shells. No `setopt`, `bindkey`, or `shopt`. |
| `zshrc` | zsh-specific: completion, directory stack, history. Sources `common.sh`. |
| `bashrc` | bash-specific: completion, history. Sources `common.sh`. |
| `starship.toml` | Prompt configuration. Works unchanged in zsh, bash, fish and PowerShell. |
| `ripgreprc` | ripgrep defaults (smart-case, search dotfiles, skip `.git`). |
| `bootstrap.sh` | Wires a shell's rc file to `common.sh`. Idempotent and non-destructive. |

## Install

```sh
git clone https://github.com/$GH_OWNER/shell-config ~/.config/shell
~/.config/shell/bootstrap.sh              # detects your shell from $SHELL
```

Or target one explicitly:

```sh
~/.config/shell/bootstrap.sh --shell zsh
~/.config/shell/bootstrap.sh --shell bash
```

Preview without writing anything:

```sh
~/.config/shell/bootstrap.sh --dry-run
```

### What bootstrap.sh guarantees

- **Idempotent.** Re-running never duplicates anything. It writes one
  marker-delimited block and rewrites that block in place on later runs.
- **Non-destructive.** Only the managed block is ever written. Every other line
  in your rc file is left byte-for-byte alone, and the file is backed up to
  `<rc>.bak-<timestamp>` before any change.
- **Conflict-aware.** If your rc already initialises fzf or zoxide, sources
  `common.sh`, or defines its own `z`, it reports the offending line numbers and
  **exits without modifying anything**. Pass `--force` to override deliberately.

Your own settings must live *outside* the markers. Anything inside is rewritten.

On bash it also ensures `~/.bash_profile` sources `~/.bashrc`, which macOS login
shells require and Linux usually already has.

## Dependencies

Everything here is **optional**. `common.sh` guards each tool with `command -v`
and silently skips whatever is not on `PATH`, so a partial install degrades
instead of erroring.

| Dependency | Needed for | macOS | Debian / Ubuntu | If missing |
|---|---|---|---|---|
| [starship](https://starship.rs) | the prompt | `brew install starship` | `curl -sS https://starship.rs/install.sh \| sh` | shell's default prompt |
| [fzf](https://github.com/junegunn/fzf) | `CTRL+R`, `CTRL+T`, `ALT+C` | `brew install fzf` | `apt install fzf` | those keys do nothing |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z`, `zi` | `brew install zoxide` | `apt install zoxide` | no `z` |
| [eza](https://github.com/eza-community/eza) | `ls`/`l`/`ll`/`la`/`lt`/`lta` | `brew install eza` | `apt install eza` (24.04+) | aliases undefined; real `ls` |
| [bat](https://github.com/sharkdp/bat) | `bat`, `bathelp`, `man` colour | `brew install bat` | `apt install bat` (binary is `batcat`) | plain `man`, no `bathelp` |
| [fd](https://github.com/sharkdp/fd) | `fda`, and fzf's file/dir source | `brew install fd` | `apt install fd-find` (binary is `fdfind`) | fzf falls back to `find` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `rg`, `ripgreprc` | `brew install ripgrep` | `apt install ripgrep` | no `rg` |
| `col` | the `MANPAGER` pipeline | base system | `apt install bsdextrautils` | `MANPAGER` is not set; plain `man` |
| bash-completion | completion **in bash only** | `brew install bash-completion@2` | `apt install bash-completion` | no completion in bash |
| [Nerd Font](https://github.com/ryanoasis/nerd-fonts) | prompt glyph, eza icons | `brew install --cask font-jetbrains-mono-nerd-font` | download + `fc-cache -f` | replacement boxes |

Two notes on Debian and Ubuntu:

- `bat` and `fd` install under different binary names (`batcat`, `fdfind`)
  because the obvious ones were already taken. `common.sh` aliases them back.
- Ubuntu's `apt` starship package lags badly; the install script is the
  maintained route.

`bootstrap.sh` itself needs only POSIX tools and is written for **bash 3.2**, so
it runs on a stock macOS as well as on Linux.

## What you get

### Keys and commands

| Keys | Action |
|---|---|
| `CTRL+R` | fuzzy search shell history — the one you will use constantly |
| `CTRL+T` | insert a file path at the cursor |
| `ALT+C` | `cd` into a subdirectory |
| `z <fragment>` | jump to a directory you have visited, ranked by frequency and recency |
| `zi` | pick that directory interactively |

`zoxide` only knows directories visited since it was installed, so it takes about
a week of normal use to become useful. `fzf` pays off immediately.

Ubuntu 22.04 ships fzf 0.29, which predates `fzf --bash`; `common.sh` falls back
to the key-binding scripts that older package installs on disk.

## File tools

| Command | Does |
|---|---|
| `ls` | `eza` — directories first, icons |
| `l` | one entry per line |
| `ll` | long listing: per-file git status, header, `long-iso` timestamps |
| `la` | same, including dotfiles |
| `lt` / `lta` | tree two levels deep / including dotfiles, minus `.git` |
| `bat FILE` | `cat` with syntax highlighting and paging |
| `bathelp CMD` | pages `CMD --help` through bat |
| `fd PATTERN` | find files; respects `.gitignore`, far faster than `find` |
| `fda PATTERN` | same, but searches dotfiles and ignored files too |
| `rg PATTERN` | recursive search; smart-case, searches dotfiles, skips `.git` |
| `man CMD` | syntax-highlighted, via `MANPAGER` |

Icons use `--icons=auto`, so they appear on a terminal and never in a pipe.
They need a Nerd Font; without one you get replacement boxes.

**`eza -h` is not `ls -h`.** In eza, `-h` means `--header`; `--human-readable`
does not exist because eza prints human sizes already. So `ls -lh` still shows
what you meant, and adds a header row. `command ls` or `\ls` reaches the real
binary whenever you want stock behaviour.

`bathelp` is deliberately not called `help` — that is a bash builtin, and
shadowing it would break `help while` and friends.

**`cat` is deliberately not aliased to `bat`.** `cat` is a POSIX tool people
reason about as behaving exactly one way, and silently changing it invites
surprises in pipelines and pasted commands. Type `bat` when you want
highlighting.

`fd` also backs fzf's `CTRL+T` and `ALT+C`, so both respect `.gitignore` and skip
`.git` — faster and quieter than the default `find` walk.

### A portability trap worth knowing

Debian and Ubuntu ship two of these under different names, because the obvious
ones were already taken by unrelated packages:

| Upstream | On Debian/Ubuntu |
|---|---|
| `bat` | `batcat` |
| `fd` | `fdfind` |

`common.sh` detects this and aliases them back, so the same commands work on
both platforms without you having to remember which machine you are on.

## Completion

macOS never runs `compinit`, so a bare zsh has **no completion system at all** —
no directory completion for `cd`, no git subcommands, no ssh hosts, no flags.
`zshrc` initialises it, caches the dump under `$XDG_CACHE_HOME/zsh`, and
re-audits only once a day, since that audit is the slowest part of zsh startup.

Matching is case-insensitive and partial-word, so `cd dow⇥` finds `Downloads`
and `cd u/l/b⇥` expands to `/usr/local/bin`.

`cd` also keeps a directory stack (`AUTO_PUSHD`), so `cd -⇥` lists where you have
been. `AUTO_CD` is deliberately left off — making a bare directory name change
directory surprises people when a directory shares a name with a command.

**bash needs a package for this**, unlike zsh:

```sh
brew install bash-completion@2      # macOS
apt install bash-completion         # Debian/Ubuntu
```

`bashrc` searches the usual locations and loads whichever it finds.

## The prompt

`starship.toml` is picked up automatically — `common.sh` sets `STARSHIP_CONFIG`
to the copy sitting beside it, so the repo can be cloned anywhere. An existing
`STARSHIP_CONFIG` in your environment is respected and never overwritten.

```
~/.config/wezterm on  main !2 ?1
🍔
```

| Element | Meaning |
|---|---|
| directory | truncated to 3 segments, or to the repo root inside a git repo |
| ` main` | current branch |
| `!2 ?1 +3 ⇡1` | modified / untracked / staged / ahead — dirty state at a glance |
| `(rebasing 2/5)` | mid-rebase or mid-merge, in red |
| `` | green when the last command succeeded, **red when it failed** |
| right side | command duration over 2s, exit code on failure, background job count |

Colours match the WezTerm Tokyo Night scheme, so prompt and terminal chrome read
as one thing. Symbols need a Nerd Font — the same
[JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) the WezTerm
config uses.

Language-version modules (node, python, rust, go) are **disabled by default**:
each one costs milliseconds on every prompt. Enable what you actually want by
flipping `disabled = false` in `starship.toml`.

### Overlap with the WezTerm status bar

Both show the git branch, deliberately. The status bar is ambient and always
current; the prompt is captured in scrollback, so weeks later you can still see
which branch a given command ran on. The prompt also carries dirty and
ahead/behind state, which the status bar does not. Drop the branch segment from
either if the duplication bothers you.

## Adding to it

Portable settings — exports, aliases, POSIX functions — go in `common.sh` and
apply to both shells everywhere. Shell-specific settings go in the rc file,
outside the managed block:

```sh
# ~/.zshrc, outside the markers
setopt HIST_IGNORE_SPACE      # bash equivalent: HISTCONTROL=ignorespace
```

## Uninstall

Delete the block between the `# >>> shell-config (managed) >>>` and
`# <<< shell-config (managed) <<<` markers in your rc file, or restore the
timestamped backup that `bootstrap.sh` wrote.
