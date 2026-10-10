#!/usr/bin/env bats
# fleet-sync against local bare repos: git@fake:JakobMelchard/<r>.git is rewritten to file://

bats_require_minimum_version 1.5.0
load helper

# remote <name> [<path> <content>]…: a bare repo under $T/remotes holding the given files
remote() {
  local n=$1 w=$T/src/$1; shift
  mkdir -p "$w"
  while [ $# -gt 0 ]; do mkdir -p "$w/$(dirname "$1")"; printf '%s\n' "$2" > "$w/$1"; shift 2; done
  mkrepo "$w"
  git clone -q --bare "$w" "$T/remotes/$n.git"
}

setup() {
  common_setup
  export FLEET_GIT_HOST=fake
  git config --global url."file://$T/remotes/".insteadOf git@fake:JakobMelchard/
  settings '{"repos": {"drifted": {}, "fresh": {}, "tpl": {}, "old": {"archived": true}, "bin": {}, "gone": {}}}'
  # .config is vendored from its latest release tag; main moves on past it
  git -C "$WS/.config" tag v1.0.0
  printf 'root = unreleased\n' > "$WS/.config/editorconfig/editorconfig"
  git -C "$WS/.config" commit -qam next && git -C "$WS/.config" update-ref refs/remotes/origin/main HEAD
  remote drifted .editorconfig 'root = false'
  remote fresh .editorconfig "# VENDORED from JakobMelchard/.config/editorconfig/editorconfig - do not edit here; run config-sync.
root = true"
  remote tpl .copier-answers.yml '_commit: v1'
  remote old .editorconfig 'root = false'
  remote bin .editorconfig 'root = false'
}

@test "no args: every listed repo except archived and platform ones" {
  run "$BIN/fleet-sync" --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" == *"fleet-sync from JakobMelchard/.config@v1.0.0"* ]] || false
  [[ "$output" == *"drifted: changed"* ]] || false
  [[ "$output" == *"    M .editorconfig"* ]] || false
  [[ "$output" == *"fresh: up to date"* ]] || false
  [[ "$output" == *"tpl: templated, skipped (copier update / Renovate)"* ]] || false
  [[ "$output" == *"gone: clone failed"* ]] || false
  [[ "$output" == *"failed: gone"* ]] || false
  [[ "$output" != *old:* ]] || false
  [[ "$output" != *bin:* ]] || false
}

@test "a header-only difference is up to date" {
  remote stale .editorconfig "# VENDORED from JakobMelchard/.config/editorconfig/editorconfig — older header.
root = true" web/tokens.css "/* VENDORED from JakobMelchard/.config tokens/tokens.css @v0.9.0. Do not edit; run config-sync. */
:root { --c: red; }" .config/tokens.path web/tokens.css
  remote bare .editorconfig 'root = true'
  run "$BIN/fleet-sync" --dry-run stale bare
  [ "$status" -eq 0 ]
  [[ "$output" == *"stale: up to date"* ]] || false
  [[ "$output" == *"bare: up to date"* ]] || false
}

@test "a failing repo fails the run after the others" {
  remote hand .config/tokens.path web/house.css web/house.css 'body { color: red; }'
  run "$BIN/fleet-sync" --dry-run hand drifted
  [ "$status" -eq 1 ]
  [[ "$output" == *"web/house.css has no VENDORED header; refusing to overwrite it"* ]] || false
  [[ "$output" == *"hand: failed"* ]] || false
  [[ "$output" == *"drifted: changed"* ]] || false
  [[ "$output" == *"failed: hand"* ]] || false
}

@test "--dry-run pushes nothing and opens no PR" {
  run "$BIN/fleet-sync" --dry-run drifted
  [ "$status" -eq 0 ]
  run ! git -C "$T/remotes/drifted.git" rev-parse -q --verify chore/fleet-sync
  run ! grep -q '^pr ' "$GH_LOG"
}

@test "a changed repo gets the branch pushed and one PR" {
  run "$BIN/fleet-sync" drifted fresh
  [ "$status" -eq 0 ]
  [[ "$output" == *"opened PR https://github.com/JakobMelchard/x/pull/1"* ]] || false
  [ "$(git -C "$T/remotes/drifted.git" log -1 --format=%s chore/fleet-sync)" = "chore: refresh vendored org config" ]
  [ "$(git -C "$T/remotes/drifted.git" show chore/fleet-sync:.editorconfig | tail -1)" = "root = true" ]
  grep -q '^pr create -R JakobMelchard/drifted --head chore/fleet-sync' "$GH_LOG"
  run ! grep -q JakobMelchard/fresh "$GH_LOG"
}

@test "a templated repo that opted in gets only its opt-ins" {
  rm -rf "$T/remotes/tpl.git" "$T/src/tpl"
  remote tpl .copier-answers.yml '_commit: v1' .config/tokens.path web/tokens.css .editorconfig 'root = false'
  run "$BIN/fleet-sync" --dry-run tpl
  [ "$status" -eq 0 ]
  [[ "$output" == *"?? web/"* ]] || false
  [[ "$output" != *".editorconfig"* ]] || false
}

@test "an unknown flag fails" {
  run "$BIN/fleet-sync" --nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown flag --nope"* ]] || false
}
