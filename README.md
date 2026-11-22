# herdr-setup

My whole [herdr](https://herdr.dev) workspace from one place: the config that binds everything to keys,
the helper scripts, and an installer that fetches, builds and wires up every tool and plugin. Each tool
and plugin stays its own repo with its own history.

## New machine

```sh
git clone https://github.com/Andree37/herdr-setup.git ~/github/Andree37/herdr-setup
~/github/Andree37/herdr-setup/install.sh
```

If herdr was not running yet, start it (`herdr`) and run `./install.sh` once more to add the plugins.
`./install.sh --dry-run` shows what it would do without changing anything. Running it again is always
safe.

It does:

- missing dependencies through Homebrew: `go`, `python3`, `jq`, `fzf`, `gh`, and herdr itself
- clones each component repo next to this one (`~/github/Andree37/<repo>`, or `$HERDR_SRC`), or pulls
  the latest if it is already there; a repo with uncommitted or unpushed work is left alone
- `ct` and `ic` (`go install`) and both tools' Claude Code hooks
- links: `config.toml` to `~/.config/herdr/config.toml`, `bin/*` to `~/.local/bin/`
- the three plugins, linked from their clones so herdr runs exactly what is on disk

## Components

| Repo | What |
|---|---|
| [code-tree](https://github.com/Andree37/code-tree) | `ct`: a dependency graph of the work in a repo, shared by you and your agents |
| [intercom](https://github.com/Andree37/intercom) | `ic`: agent sessions (and you) message each other |
| [herdr-ct](https://github.com/Andree37/herdr-ct) | `prefix+t`: code-tree pane beside the agent |
| [herdr-intercom](https://github.com/Andree37/herdr-intercom) | `prefix+i`: intercom pane |
| [herdr-views](https://github.com/Andree37/herdr-views) | `prefix+a` agents, `prefix+p` PRs, `prefix+shift+l` links, `prefix+o` / `prefix+shift+o` back and forward, `prefix+n` the agent that needs you |

And in this repo:

| Path | What |
|---|---|
| `config.toml` | herdr config: keys for everything above, sidebar tree, Agents panel as a "needs you" queue |
| `bin/herdr-sessionizer` | `prefix+f`: jump to an open tab or start claude in any project under `~/github` |
| `bin/herdr-new` | start another claude session in a folder, as a new space or tab |
| `bin/herdr-agents` | `save` before a reboot, `up` after it: brings every agent back into its conversation |

## Changing things

Work in each component's own repo as usual: edit, commit, push. Plugins are live as soon as you
reopen their pane. After changing `code-tree` or `intercom`, run `./install.sh` (or `go install ./cmd/ct`
/ `./cmd/ic` in that repo) to rebuild the binary. On another machine, `./install.sh` pulls everything.
