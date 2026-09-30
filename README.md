# bin — org tooling

Shell tools for running the `JakobMelchard` platform. Private. Put this directory on `PATH`.

| Tool | Does |
|------|------|
| `org-repo new <name> --template <t>` | render [`JakobMelchard/template`](https://github.com/JakobMelchard/template) with copier (`uvx copier copy`; it writes every file: devcontainer, vendored configs, `.pre-commit-config.yaml`, CI caller, README, scaffold), then create the private repo, push and apply settings. `t`: `hx-app` `cf` `go` `py` `c-cpp` `infra` `ios` `macos`; `--ref` picks a template tag or branch |
| `org-repo ls` · `settings` · `sync` · `apps` · `labels` | list repos · show settings drift vs `.github/infra/settings.json` · apply settings via `gh api` · show app installations · apply the declared labels to every repo |
| `config-sync [--check] [--ref <ref>] [--examples] [group…]` | copy ruff/gitleaks/editorconfig/swift-format from `.config` per its manifest into a repo not rendered from the template; groups limit to e.g. `ruff`. JS configs come from the npm package `@jakobmelchard/config` instead. Opt-in groups (`tokens`, the org web design tokens) sync only into repos that carry the named file, templated or not: `.config/tokens.path` holds the destination on its first line (e.g. `internal/ui/static/tokens.css`). `--check` writes nothing and exits 1 on drift, ignoring the `VENDORED` header line; with no group it checks the copies the repo carries plus its opt-ins, so CI can run it. `--ref` vendors from a `.config` tag or branch instead of `main` |
| `dev-init <template>` | copy a devcontainer template (`template/devcontainer/templates/<t>`, formerly the `.devcontainer` repo) into a repo not rendered from the template |
| `ci [repo…]` | latest CI conclusion per repo |
| `ios devices` · `status` · `boot` · `gen` · `build` · `test` · `install` · `launch` · `run` · `screenshot` · `logs` · `uninstall` | iOS apps on a simulator (`--sim`, default) or the attached iPad (`--device`): xcodegen when `project.yml` is present, `xcodebuild` into `build/DerivedData`, `simctl`/`devicectl`/`idevicescreenshot` for install, launch and screenshots. `IOS_SIM`, `IOS_DEVICE`, `IOS_SCHEME`, `IOS_CONFIG` override the defaults; `TEST_RUNNER_*` env vars reach XCUITests. macOS + Xcode only. |
| `fleet-sync [--dry-run] [repo…]` | refresh vendored configs in every pre-template repo that carries them, and opt-in groups (tokens) in every repo that opted in, one PR per changed repo; templated repos (`.copier-answers.yml`) get only their opt-ins; `.github/workflows/fleet-sync.yml` runs it weekly with the org app |

Each tool reads its source repo from the local workspace clone (`~/Workspaces/JakobMelchard/<repo>`) when present, else via `gh api` tarball — private repos, no raw URLs. `FETCH_REMOTE=1` forces the tarball.

Templated repos (`.copier-answers.yml` at the root) take file updates from the template only:
`uvx copier update --defaults`, or merge the PR Renovate's copier manager opens when the template is tagged.
`config-sync`, `dev-init` and `fleet-sync` leave them alone; those three remain for the repos created
before the template, until they adopt it (`uvx copier copy --defaults -d template=<t> https://github.com/JakobMelchard/template.git .`
in the repo, review the diff).

Settings live once, in `.github/infra/settings.json`. `tofu` in `.github/infra` applies them declaratively (needs an admin token for org-level keys); `org-repo sync` applies the repo-level subset with the plain `repo` scope.

Git hooks are not vendored: each repo pins `JakobMelchard/.githooks` in `.pre-commit-config.yaml`. On a new machine: `brew install prek`, then `prek install` once per clone.

bash 3.2. `lib/common.sh` is sourced by every tool.
