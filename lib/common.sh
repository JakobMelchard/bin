#!/usr/bin/env bash
# Shared helpers for JakobMelchard/bin. Sourced, not executed. bash 3.2.
ORG="${ORG:-JakobMelchard}"
# absolute path of this bin dir, resolved before any tool cd's away — a relative
# $(dirname "$0") stops working after `cd` (org-repo new bit this)
BIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WS="${WORKSPACES_ROOT:-$HOME/Workspaces}/$ORG"

die()  { echo "${0##*/}: $*" >&2; exit 1; }
say()  { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
need() { for c in "$@"; do have "$c" || die "needs $c"; done; }

root() { git rev-parse --show-toplevel 2>/dev/null || die "not in a git repo"; }

# fetch <repo> [ref]  -> prints a temp dir holding a checkout of $ORG/<repo>
# Uses the local workspace clone when present, else a gh tarball (private-safe).
fetch() {
  local repo=$1 ref=${2:-main} d
  if [ -z "${FETCH_REMOTE:-}" ] && [ -d "$WS/$repo/.git" ]; then
    printf '%s\n' "$WS/$repo"; return
  fi
  need gh
  d=$(mktemp -d)
  gh api "repos/$ORG/$repo/tarball/$ref" > "$d/t.tgz"
  tar -xzf "$d/t.tgz" -C "$d" --strip-components=1
  rm -f "$d/t.tgz"
  printf '%s\n' "$d"
}

# vendor <src> <dst> <label>: copy with a one-line provenance header where the format has comments
vendor() {
  local src=$1 dst=$2 label=$3
  mkdir -p "$(dirname "$dst")"
  case "$dst" in
    *.js)   { echo "// VENDORED from $ORG/$label — do not edit here; run config-sync."; cat "$src"; } > "$dst" ;;
    *.toml|*.yml|*.yaml|*editorconfig)
            { echo "# VENDORED from $ORG/$label — do not edit here; run config-sync."; cat "$src"; } > "$dst" ;;
    *)      cp "$src" "$dst" ;;   # json/markdown: no comment syntax, copied verbatim
  esac
  say "  $dst"
}

settings_json() { # prints .github/infra/settings.json (live from the org, or local clone)
  local d; d=$(fetch .github)
  cat "$d/infra/settings.json"
}
