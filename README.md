# bin — org tooling

Shell tools for running the `JakobMelchard` platform. Private. Put this directory on `PATH`.

| Tool | Does |
|------|------|
| `org-repo new <name> --template <t>` | create a private repo, apply a devcontainer template, vendor configs/hooks/skills, write the CI caller, push, apply settings |
| `org-repo ls` · `settings` · `sync` · `apps` | list repos · show settings drift vs `.github/infra/settings.json` · apply settings via `gh api` · show app installations |
| `hooks-install [ref]` | vendor `.githooks` into the current repo (`.githooks/` + `core.hooksPath`) |
| `agents-sync [skill…]` | copy org `AGENTS.md` + skills from `.agents` into `./.agents/` |
| `config-sync [--examples]` | copy lint/format configs from `.config` per its manifest |
| `dev-init <template>` | copy a `.devcontainer` template into the current repo |
| `ci [repo…]` | latest CI conclusion per repo |

Each tool reads its source repo from the local workspace clone (`~/Workspaces/JakobMelchard/<repo>`) when present, else via `gh api` tarball — private repos, no raw URLs. `FETCH_REMOTE=1` forces the tarball.

Settings live once, in `.github/infra/settings.json`. `tofu` in `.github/infra` applies them declaratively (needs an admin token for org-level keys); `org-repo sync` applies the repo-level subset with the plain `repo` scope.

On a machine without this repo yet: `curl -fsSL https://gist.githubusercontent.com/lilfeelz/c5e63e7e510aeffb7766a1b10b607321/raw/install-hooks.sh | bash` installs the hooks alone (needs `gh auth`).

bash 3.2. `lib/common.sh` is sourced by every tool.
