#!/usr/bin/env bash
# Shared helpers for JakobMelchard/bin. Sourced, not executed. bash 3.2.
ORG="${ORG:-JakobMelchard}"
# absolute path of this bin dir, resolved before any tool cd's away — a relative
# $(dirname "$0") stops working after `cd` (org-repo new bit this)
# shellcheck disable=SC2034 # used by every tool that sources this
BIN=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WS="${WORKSPACES_ROOT:-$HOME/Workspaces}/$ORG"

die()  { echo "${0##*/}: $*" >&2; exit 1; }
say()  { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
need() { for c in "$@"; do have "$c" || die "needs $c"; done; }

root() { git rev-parse --show-toplevel 2>/dev/null || die "not in a git repo"; }

# fetch <repo> [ref]  -> prints a temp dir holding a checkout of $ORG/<repo>
# No ref: the local workspace clone when it is clean and at origin/main, else a gh tarball of main.
# Explicit ref: always the gh tarball (private-safe), so the ref is what gets vendored.
fetch() {
  local repo=$1 ref=${2:-} c="$WS/$1" d
  if [ -z "${FETCH_REMOTE:-}" ] && [ -z "$ref" ] && [ -d "$c/.git" ]; then
    if [ -z "$(git -C "$c" status --porcelain)" ] &&
       [ "$(git -C "$c" rev-parse HEAD)" = "$(git -C "$c" rev-parse -q --verify origin/main)" ]; then
      printf '%s\n' "$c"; return
    fi
    echo "${0##*/}: warning: $c is dirty or not at origin/main; using $ORG/$repo@main from GitHub" >&2
  fi
  ref=${ref:-main}
  need gh
  d=$(mktemp -d)
  # command substitution drops set -e in bash 3.2, so check each step
  gh api "repos/$ORG/$repo/tarball/$ref" > "$d/t.tgz" || die "cannot fetch $ORG/$repo@$ref"
  tar -xzf "$d/t.tgz" -C "$d" --strip-components=1 || die "cannot unpack $ORG/$repo@$ref"
  rm -f "$d/t.tgz"
  printf '%s\n' "$d"
}

# vendor <src> <dst> <label>: copy with a one-line provenance header where the format has comments
vendor() {
  local src=$1 dst=$2 label=$3
  mkdir -p "$(dirname "$dst")"
  case "$dst" in
    *.js)   { echo "// VENDORED from $ORG/$label - do not edit here; run config-sync."; cat "$src"; } > "$dst" ;;
    *.toml|*.yml|*.yaml|*editorconfig)
            { echo "# VENDORED from $ORG/$label - do not edit here; run config-sync."; cat "$src"; } > "$dst" ;;
    *)      cp "$src" "$dst" ;;   # json/markdown: no comment syntax, copied verbatim
  esac
  say "  $dst"
}

settings_json() { # prints .github/infra/settings.json (live from the org, or local clone)
  local d; d=$(fetch .github)
  cat "$d/infra/settings.json"
}
