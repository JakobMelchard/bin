# bin

Extensionless bash scripts, `lib/common.sh` sourced by all. bash 3.2: no `mapfile`, no `declare -A`.
Each tool: one concern, `set -euo pipefail`, `die` on misuse, prints what it wrote.
Never fetch a private repo over `raw.githubusercontent.com`; use `fetch <repo>` from the lib.
`config-sync` output goes through `vendor`/`vendor_check` in the lib (one provenance header per format, `--check`
ignores that line); manifest `opt_in` groups are per-repo and sync even in templated repos.
Check with `bash -n` and `shellcheck --severity=warning` before committing.
Files a new repo starts with belong to `JakobMelchard/template` (copier), not to `org-repo`: `org-repo new`
renders it and keeps only the GitHub side (create, push, settings, labels). Do not add heredoc scaffolds here.
