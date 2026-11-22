# herdr-setup

My whole [herdr](https://herdr.dev) workspace in one repo: the tools, the plugins that put them in
herdr, the config that binds them to keys, and the helper scripts. One clone and one command set up a
new machine.

## New machine

```sh
git clone --recursive https://github.com/Andree37/herdr-setup.git ~/github/Andree37/herdr-setup
cd ~/github/Andree37/herdr-setup
./install.sh
```

If herdr was not running yet, start it (`herdr`) and run `./install.sh` once more to add the plugins.
`./install.sh --dry-run` shows what it would do without changing anything. Running it again is always
safe.

It installs:

- missing dependencies through Homebrew: `go`, `python3`, `jq`, `fzf`, `gh`, and herdr itself
- `ct` and `ic` from the tool submodules (`go install`), and both tools' Claude Code hooks
  (`ct install claude`, `ic install claude`)
- links: `config.toml` to `~/.config/herdr/config.toml`, `bin/*` to `~/.local/bin/`
- the three plugins, linked from their submodules so herdr runs exactly this checkout

## What's inside

| Path | What |
|---|---|
| `config.toml` | herdr config: keys for everything below, sidebar tree, Agents panel as a "needs you" queue |
| `bin/herdr-sessionizer` | `prefix+f`: jump to an open tab or start claude in any project under `~/github` |
| `bin/herdr-new` | start another claude session in a folder, as a new space or tab |
| `bin/herdr-agents` | `save` before a reboot, `up` after it: brings every agent back into its conversation |
| `tools/code-tree` | `ct`: a dependency graph of the work in a repo, shared by you and your agents |
| `tools/intercom` | `ic`: agent sessions (and you) message each other |
| `plugins/herdr-ct` | `prefix+t`: code-tree pane beside the agent |
| `plugins/herdr-intercom` | `prefix+i`: intercom pane |
| `plugins/herdr-views` | `prefix+a` agents, `prefix+p` PRs, `prefix+shift+l` links, `prefix+o` / `prefix+shift+o` back and forward, `prefix+n` the agent that needs you |

## Changing things

The submodules are ordinary clones of their own repos. Work in them, commit and push there, then record
the new versions here:

```sh
cd tools/intercom && git switch main && ...   # edit, commit, push as usual
cd ../.. && git add tools/intercom && git commit -m "chore: bump intercom"
./install.sh                                  # rebuilds ct/ic; reopen panes to see changes
```

To pull everyone's latest: `git pull && git submodule update --init --remote && ./install.sh`.
