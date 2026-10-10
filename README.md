# bin

Dissolved 2026-10-10. This repo held the org shell tools; each now lives with the repo it serves, with its
tests and history copied from here (source commit `78cd436`). Archived: nothing is added.

| Tool | New home | Call |
|------|----------|------|
| `config-sync`, `fleet-sync` | [`JakobMelchard/.config`](https://github.com/JakobMelchard/.config) `scripts/` | `~/Workspaces/JakobMelchard/.config/scripts/<tool>` |
| `org-repo` (`new`, `ls`) | [`JakobMelchard/template`](https://github.com/JakobMelchard/template) `scripts/` | `~/Workspaces/JakobMelchard/template/scripts/org-repo` |
| `ci`, `lib/common.sh` | [`JakobMelchard/.github`](https://github.com/JakobMelchard/.github) `scripts/` | `~/Workspaces/JakobMelchard/.github/scripts/ci` |
| `ios` | [`lilfeelz/workspaces`](https://github.com/lilfeelz/workspaces) `attach/scripts/` | `scripts/ios` from `attach/` |

Retired: `dev-init` (copier renders the devcontainer), and `org-repo settings`, `apps` and `labels` (`tofu plan`,
`gh api orgs/JakobMelchard/installations`, `labels.yml`). `org-repo sync` is no longer a command; `org-repo new`
still applies the repo defaults to the repo it creates.

The tools source `JakobMelchard/.github` `scripts/lib/common.sh`; see `JakobMelchard/.agents` `PLATFORM.md`, Tools.
