# bin

Extensionless bash scripts, `lib/common.sh` sourced by all. bash 3.2: no `mapfile`, no `declare -A`.
Each tool: one concern, `set -euo pipefail`, `die` on misuse, prints what it wrote.
Never fetch a private repo over `raw.githubusercontent.com`; use `fetch <repo>` from the lib.
Check with `bash -n` and `shellcheck --severity=warning` before committing.
