# Shared setup for the bats suite. Offline: gh is test/bin/gh, every repo is a local temp repo,
# the org clones live under $WORKSPACES_ROOT so fetch() reads them instead of GitHub.

# mkrepo <dir>: commit everything in <dir> and mark it as at origin/main (what fetch() trusts)
mkrepo() {
  git -C "$1" init -q -b main
  git -C "$1" add -A
  git -C "$1" commit -q -m init
  git -C "$1" update-ref refs/remotes/origin/main HEAD
}

# settings <json>: JakobMelchard/.github holding <json> as infra/settings.json
settings() {
  mkdir -p "$WS/.github/infra"
  printf '%s\n' "$1" > "$WS/.github/infra/settings.json"
  mkrepo "$WS/.github"
}

common_setup() {
  unset GITHUB_ACTIONS GH_TOKEN FETCH_REMOTE ORG FLEET_GIT_HOST
  T=$BATS_TEST_TMPDIR
  export WORKSPACES_ROOT=$T/ws GH_LOG=$T/gh.log GH_FIXTURES=$T/fx
  export GIT_CONFIG_GLOBAL=$T/gitconfig GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  PATH="$BATS_TEST_DIRNAME/bin:$PATH"
  # shellcheck disable=SC2034 # used by the .bats files
  BIN=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
  WS=$WORKSPACES_ROOT/JakobMelchard
  : > "$GH_LOG"
  mkdir -p "$GH_FIXTURES"
  git config --global init.defaultBranch main

  # JakobMelchard/.config: one plain group, one opt-in group, one example
  c=$WS/.config
  mkdir -p "$c/editorconfig" "$c/ruff" "$c/tokens" "$c/renovate"
  printf 'root = true\n' > "$c/editorconfig/editorconfig"
  printf 'line-length = 100\n' > "$c/ruff/ruff.toml"
  printf ':root { --c: red; }\n' > "$c/tokens/tokens.css"
  printf '{}\n' > "$c/renovate/default.json"
  cat > "$c/manifest.json" <<'EOF'
{
  "files": { "editorconfig/editorconfig": ".editorconfig", "ruff/ruff.toml": ".config/ruff.toml" },
  "opt_in": { "tokens/tokens.css": ".config/tokens.path" },
  "examples": { "renovate/default.json": "renovate.json" }
}
EOF
  mkrepo "$c"

  # the consumer repo config-sync runs in
  R=$T/repo
  mkdir -p "$R"
  git -C "$R" init -q -b main
}
