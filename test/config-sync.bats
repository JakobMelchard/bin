#!/usr/bin/env bats
# config-sync: manifest parsing, opt-in groups, --check drift detection, --ref via the gh tarball

load helper
setup() { common_setup; }

@test "syncs every plain group with a provenance header, skips opt-ins without their file" {
  cd "$R"
  run "$BIN/config-sync"
  [ "$status" -eq 0 ]
  [ "$(head -1 .editorconfig)" = "# VENDORED from JakobMelchard/.config/editorconfig/editorconfig - do not edit here; run config-sync." ]
  [ "$(tail -1 .config/ruff.toml)" = "line-length = 100" ]
  [ ! -e renovate.json ]
  [[ "$output" != *tokens* ]] || false
}

@test "a group argument limits the sync" {
  cd "$R"
  run "$BIN/config-sync" ruff
  [ "$status" -eq 0 ]
  [ -f .config/ruff.toml ]
  [ ! -e .editorconfig ]
}

@test "an unknown group fails" {
  cd "$R"
  run "$BIN/config-sync" nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"no group nope in JakobMelchard/.config@"*"manifest.json"* ]] || false
}

@test "an opt-in group needs its path file" {
  cd "$R"
  run "$BIN/config-sync" tokens
  [ "$status" -eq 1 ]
  [[ "$output" == *"tokens is opt-in: write its destination path into .config/tokens.path first"* ]] || false
}

@test "an opt-in group syncs to the path on the first line of its file" {
  cd "$R"
  mkdir -p .config && printf '  web/tokens.css  \nignored\n' > .config/tokens.path
  run "$BIN/config-sync" tokens
  [ "$status" -eq 0 ]
  [[ "$(head -1 web/tokens.css)" == "/* VENDORED from JakobMelchard/.config tokens/tokens.css @"*". Do not edit; run config-sync. */" ]] || false
  [ "$(tail -1 web/tokens.css)" = ":root { --c: red; }" ]
}

@test "an opt-in path outside the repo is refused" {
  cd "$R"
  mkdir -p .config && echo ../x.css > .config/tokens.path
  run "$BIN/config-sync" tokens
  [ "$status" -eq 1 ]
  [[ "$output" == *"want a repo-relative destination path"* ]] || false
}

@test "--check passes on fresh copies and writes nothing" {
  cd "$R"
  "$BIN/config-sync" >/dev/null
  rm .config/ruff.toml
  run "$BIN/config-sync" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok .editorconfig"* ]] || false
  [ ! -e .config/ruff.toml ]
}

@test "--check ignores a header-only change" {
  cd "$R"
  "$BIN/config-sync" >/dev/null
  printf '# VENDORED from somewhere else @v0\nroot = true\n' > .editorconfig
  run "$BIN/config-sync" --check
  [ "$status" -eq 0 ]
}

@test "--check reports drift with a diff and exits 1" {
  cd "$R"
  "$BIN/config-sync" >/dev/null
  echo 'line-length = 80' >> .config/ruff.toml
  run "$BIN/config-sync" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"drift .config/ruff.toml"* ]] || false
  [[ "$output" == *"-line-length = 80"* ]] || false
  [[ "$output" == *"vendored copies drifted from JakobMelchard/.config; run config-sync"* ]] || false
}

@test "--check with a group reports a missing copy" {
  cd "$R"
  run "$BIN/config-sync" --check ruff
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing .config/ruff.toml"* ]] || false
}

@test "--check covers opt-ins" {
  cd "$R"
  mkdir -p .config && echo web/tokens.css > .config/tokens.path
  "$BIN/config-sync" tokens >/dev/null
  echo ':root{}' > web/tokens.css
  run "$BIN/config-sync" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"drift web/tokens.css"* ]] || false
}

@test "--check and --examples do not mix" {
  cd "$R"
  run "$BIN/config-sync" --check --examples
  [ "$status" -eq 1 ]
}

@test "--examples seeds once" {
  cd "$R"
  run "$BIN/config-sync" --examples
  [[ "$output" == *"seed renovate.json"* ]] || false
  run "$BIN/config-sync" --examples
  [[ "$output" == *"keep renovate.json (exists)"* ]] || false
}

@test "a templated repo refuses plain groups but syncs opt-ins" {
  cd "$R"
  touch .copier-answers.yml
  run "$BIN/config-sync" ruff
  [ "$status" -eq 1 ]
  [[ "$output" == *"uvx copier update --defaults"* ]] || false
  mkdir -p .config && echo web/tokens.css > .config/tokens.path
  run "$BIN/config-sync"
  [ "$status" -eq 0 ]
  [ -f web/tokens.css ]
  [ ! -e .editorconfig ]
}

@test "--ref vendors from the gh tarball and stamps the tag" {
  cd "$R"
  mkdir -p .config && echo web/tokens.css > .config/tokens.path
  run "$BIN/config-sync" --ref v1.2.3 tokens
  [ "$status" -eq 0 ]
  [[ "$output" == "config-sync @v1.2.3 (v1.2.3) -> "* ]] || false
  [[ "$(head -1 web/tokens.css)" == *"@v1.2.3. Do not edit"* ]] || false
  grep -qx 'api repos/JakobMelchard/.config/tarball/v1.2.3' "$GH_LOG"
}

@test "a dirty .config clone falls back to the tarball of main" {
  cd "$R"
  echo dirty > "$WS/.config/untracked"
  run "$BIN/config-sync" ruff
  [ "$status" -eq 0 ]
  [[ "$output" == *"is dirty or not at origin/main"* ]] || false
  [[ "$output" == *"(abc1234)"* ]] || false
}
