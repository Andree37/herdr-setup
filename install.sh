#!/usr/bin/env bash
# Set up the whole herdr workspace on this machine: tools, plugins, config, scripts.
# Safe to run again at any time; it only changes what is out of date.
#
#   ./install.sh            everything
#   ./install.sh --dry-run  print what it would do, change nothing
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
stamp="$(date +%Y%m%d%H%M%S)"
dry=0
[ "${1:-}" = "--dry-run" ] && dry=1

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
run() {
  if [ "$dry" = 1 ]; then echo "  would run: $*" >&2; else "$@"; fi
}

export PATH="$HOME/.local/bin:$HOME/go/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# ---------------------------------------------------------------- dependencies

say "dependencies"
missing=()
for tool in git go python3 jq fzf gh; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
  if command -v brew >/dev/null 2>&1; then
    pkgs=()
    for tool in "${missing[@]}"; do
      case "$tool" in python3) pkgs+=(python) ;; *) pkgs+=("$tool") ;; esac
    done
    run brew install "${pkgs[@]}"
  else
    echo "missing: ${missing[*]}. Install them with your package manager, then run this again." >&2
    exit 1
  fi
fi
if ! command -v herdr >/dev/null 2>&1; then
  say "herdr (to ~/.local/bin)"
  if [ "$dry" = 1 ]; then echo "  would run: curl -fsSL https://herdr.dev/install.sh | sh"
  else curl -fsSL https://herdr.dev/install.sh | sh; fi
fi
gh auth status >/dev/null 2>&1 || echo "note: run \`gh auth login\` so herdr-views can show your PRs"

# ---------------------------------------------------------------- sources

say "submodules"
run git -C "$repo" submodule update --init --recursive

# ---------------------------------------------------------------- tools

say "tools: ct (code-tree) and ic (intercom)"
for tool in code-tree:ct intercom:ic; do
  dir="${tool%%:*}" bin="${tool##*:}"
  if [ "$dry" = 1 ]; then echo "  would run: go install ./cmd/$bin   (in tools/$dir)"
  else (cd "$repo/tools/$dir" && go install "./cmd/$bin") && echo "  installed $bin"; fi
done
settings="$HOME/.claude/settings.json"
for bin in ct ic; do   # Claude Code hooks, skipped when already there
  if [ -f "$settings" ] && grep -qF "/$bin hook " "$settings"; then
    echo "  $bin hooks already in ~/.claude/settings.json"
  else
    run "$(go env GOPATH)/bin/$bin" install claude
  fi
done

# ---------------------------------------------------------------- config and scripts

say "config and scripts"
link() {
  local src="$repo/$1" dest="$HOME/$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return
  fi
  if [ "$dry" = 1 ]; then echo "  would link ~/$2 -> $1"; return; fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak.$stamp"
    echo "  backed up ~/$2 to ~/$2.bak.$stamp"
  fi
  ln -s "$src" "$dest"
  echo "  linked ~/$2"
}
link config.toml .config/herdr/config.toml
for script in "$repo"/bin/*; do
  link "bin/$(basename "$script")" ".local/bin/$(basename "$script")"
done

# ---------------------------------------------------------------- plugins

say "herdr plugins"
if ! herdr plugin list >/dev/null 2>&1; then
  echo "  herdr is not running. Start it (\`herdr\`), then run ./install.sh again to add the plugins."
  exit 0
fi
listed="$(herdr plugin list 2>/dev/null)"
for dir in "$repo"/plugins/*/; do
  dir="${dir%/}"
  id="$(sed -n 's/^id = "\(.*\)"/\1/p' "$dir/herdr-plugin.toml" | head -1)"
  line="$(printf '%s\n' "$listed" | grep -F -- "- $id " || true)"
  case "$line" in
    *"[local:$dir]"*) echo "  $id already linked"; continue ;;
    *"[local:"*) run herdr plugin unlink "$id" >/dev/null ;;
    "") ;;
    *) run herdr plugin uninstall "$id" >/dev/null ;;
  esac
  run herdr plugin link "$dir" >/dev/null
  [ "$dry" = 1 ] || echo "  linked $id"
done

# herdr-views keeps a background loop (sidebar tree, focus history). herdr
# starts it with the server; start it now too, so nothing waits for a restart.
# One left running from another checkout is stopped first.
pidfile="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-views/annotate.pid"
if [ -f "$pidfile" ] && pid="$(cat "$pidfile")" && kill -0 "$pid" 2>/dev/null &&
  ! ps -o command= -p "$pid" | grep -qF "$repo/plugins/herdr-views/"; then
  run kill "$pid"
  sleep 0.5
fi
run env HERDR_PLUGIN_ID=local.herdr-views sh "$repo/plugins/herdr-views/annotate-startup.sh"
run herdr server reload-config >/dev/null
say "done"
