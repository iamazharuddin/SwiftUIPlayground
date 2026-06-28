# `Scripts/`

Small, focused shell/Ruby helpers the pipeline calls — kept as files (not inline YAML) so they're
testable locally and reusable across workflows.

Planned scripts:

| Script | Purpose | Part |
|--------|---------|------|
| `bootstrap.sh` | install pinned tooling (mise/brew, bundler) | 6 |
| `set_build_number.sh` | derive build number from git (e.g. commit count) | 20 |
| `decode_secrets.sh` | materialize base64 secrets/keys into files at runtime | 10 |

> Empty for now — real content arrives alongside the relevant Parts.
