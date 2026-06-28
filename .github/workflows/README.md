# `.github/workflows/`

GitHub Actions reads every `*.yml` here and runs the ones whose `on:` matches the event
(see [docs/cicd/part-02](../../docs/cicd/part-02-github-internals.md)).

Planned workflows (filled in during the masterclass):

| File | Trigger | Purpose | Part |
|------|---------|---------|------|
| `ci.yml` | push to feature/**, PRs → develop/main | lint · build · unit/UI test · Danger | 4–5 |
| `beta.yml` | merge to develop/main | archive · sign · upload TestFlight · notify | 5, 15 |
| `release.yml` | tag `v*` | archive Release · upload App Store Connect · submit | 16 |

> Empty for now — the real, commented workflows are written in Batch 2 onward.
