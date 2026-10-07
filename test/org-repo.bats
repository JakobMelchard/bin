#!/usr/bin/env bats
# org-repo and ci against the fake gh: repo listing, settings drift, sync, apps

load helper

setup() {
  common_setup
  echo '[{"name":"b","isArchived":false},{"name":"a","isArchived":false},{"name":"z","isArchived":true}]' > "$GH_FIXTURES/repos.json"
  echo '{"has_wiki": false}' > "$GH_FIXTURES/repo.json"
  settings '{"repo_defaults": {"has_wiki": false, "vulnerability_alerts": true}, "repos": {}}'
}

@test "usage on no command" {
  run "$BIN/org-repo"
  [ "$status" -eq 2 ]
  [[ "$output" == *"org-repo new <name>"* ]] || false
}

@test "settings: no args checks every repo, archived included" {
  run "$BIN/org-repo" settings
  [ "$status" -eq 0 ]
  [ "$output" = "no drift" ]
  [ "$(grep -E '^api repos/JakobMelchard/[a-z]$' "$GH_LOG")" = "$(printf 'api repos/JakobMelchard/%s\n' a b z)" ]
}

@test "settings: reports drift and exits 1" {
  echo '{"has_wiki": true}' > "$GH_FIXTURES/repo.json"
  run "$BIN/org-repo" settings a
  [ "$status" -eq 1 ]
  [ "$output" = "$(printf 'a\n    has_wiki: live=true want=false')" ]
}

@test "sync: no args patches every non-archived repo" {
  run "$BIN/org-repo" sync
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf 'a: {"has_wiki":false}\nb: {"has_wiki":false}')" ]
  [ "$(grep -c '^api -X PATCH' "$GH_LOG")" -eq 2 ]
  grep -qx 'api -X PUT repos/JakobMelchard/a/vulnerability-alerts' "$GH_LOG"
}

@test "apps: a selected installation the token cannot list" {
  echo '{"installations":[{"id":1,"app_slug":"one","repository_selection":"all"},{"id":2,"app_slug":"two","repository_selection":"selected"}]}' > "$GH_FIXTURES/installations.json"
  run "$BIN/org-repo" apps
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf 'one: all\ntwo: selected repos (list needs an app user token)')" ]
}

@test "ci: no args lists every non-archived repo" {
  run "$BIN/ci"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%-26s %-10s %-18s %s\n%-26s %s\n%-26s %s' REPO STATUS WORKFLOW WHEN a - b -)" ]
}
