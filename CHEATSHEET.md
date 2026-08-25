# Retraining cheatsheet

Old habits and what replaces them. The old commands all still work — nothing here
is mandatory. `bat ~/.config/shell/CHEATSHEET.md` to reread this.

Terminal navigation (panes, tabs, workspaces) lives in the WezTerm repo's
`KEYS.md`, not here.

## The swap table

| Muscle memory | New | Why bother |
|---|---|---|
| `↑ ↑ ↑ ↑ ↑` | **`CTRL+R`** then any fragment | finds a command from three weeks ago in two keystrokes |
| `cd ~/some/long/path` | **`z path`** | matches on any fragment, ranked by how often you go there |
| `ls -la` | **`ll`** / **`la`** | adds per-file git status and aligned columns |
| `cat config.toml` | **`bat config.toml`** | syntax highlighting, line numbers |
| `find . -name '*.ts'` | **`fd .ts`** | shorter, faster, skips `.gitignore`d noise |
| `grep -rn pattern .` | **`rg pattern`** | ~10× faster, skips `.git`, smart-case |
| `ls` then `cd` then `ls` again | **`lt`** | tree view, two levels, one command |
| `cmd --help \| less` | **`bathelp cmd`** | highlighted and paged |
| `man cmd` | **`man cmd`** | unchanged, but now syntax-highlighted |

## What changed without you asking

Three things now happen while you type:

- **Grey ghost text** completes the line from history. `→` accepts it. Ignore it
  by continuing to type — it is never inserted unless you press `→`.
- **Your command turns red** if it does not resolve, green if it does. A typo is
  visible *before* you press enter.
- **`TAB` opens a fuzzy picker** instead of listing options. Type to narrow,
  arrows to move, enter to pick. `cd` gets a directory preview.

## Learn it in two weeks

Trying to adopt everything at once is how it all reverts. Pick three.

**Week one — the big wins**

1. `CTRL+R` instead of `↑`. Force it: if you catch yourself pressing `↑` more
   than twice, stop and use `CTRL+R`.
2. `z` instead of `cd` for anywhere you have been before. It needs a few days of
   your normal `cd` habits before it knows your directories.
3. `→` to accept a ghost suggestion. The smallest change, the fastest payoff.

**Week two — the search tools**

4. `rg pattern` instead of `grep -rn pattern .`
5. `fd name` instead of `find . -name '*name*'`
6. `LEADER |` and `LEADER z` for panes, instead of opening another window.

## Escape hatches

Decades of habit beats any alias. When you want the original:

| Want | Do |
|---|---|
| the real `ls`, not eza | `command ls` or `\ls` |
| a real `find` / `grep` | they were never aliased — just use them |
| plain `cat` | never aliased either |
| drop an alias for this session | `unalias ll` |
| see what an alias actually runs | `alias ll` or `which ll` |
| what is this thing? | `type foo` — says alias, function, or binary |

## Reading the prompt

```
~/.config/shell on  main !2 ?1
▶                                                  3s ✘ 1
```

| Piece | Meaning |
|---|---|
| ` main` | current branch |
| `!2` | 2 modified files |
| `?1` | 1 untracked file |
| `+3` | 3 staged |
| `⇡1` `⇣2` | commits ahead / behind the remote |
| `▶` green / red | last command succeeded / failed |
| `3s` (right) | that command took 3 seconds |
| `✘ 1` (right) | exit code, shown only on failure |
| `🔍127` (right) | 127 means command not found |

## When something is missing

Aliases and tools load when a shell **starts**. If `ll` says "command not
found", your shell predates the config:

```sh
exec zsh        # replaces the current shell, keeps the pane and directory
```

`starship.toml` is the exception — it is re-read on every prompt, so prompt
edits appear immediately.
