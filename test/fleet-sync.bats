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
  remote drifted .editorconfig 'root = false'
  remote fresh .editorconfig "# VENDORED from JakobMelchard/.config/editorconfig/editorconfig - do not edit here; run config-sync.
root = true"
  remote tpl .copier-answers.yml '_commit: v1'
  remote old .editorconfig 'root = false'
  remote bin .editorconfig 'root = false'
}

@test "no args: every listed repo except archived and platform ones" {
  run "$BIN/fleet-sync" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"drifted: changed"* ]] || false
  [[ "$output" == *"    M .editorconfig"* ]] || false
  [[ "$output" == *"fresh: up to date"* ]] || false
  [[ "$output" == *"tpl: templated, skipped (copier update / Renovate)"* ]] || false
  [[ "$output" == *"gone: clone failed, skipped"* ]] || false
  [[ "$output" != *old:* ]] || false
  [[ "$output" != *bin:* ]] || false
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
