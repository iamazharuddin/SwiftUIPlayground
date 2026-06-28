# `fastlane/`

The single source of truth for **how** the app is built, tested, signed, and shipped. The CI
workflows stay thin and call lanes here (`bundle exec fastlane <lane>`), so humans and CI run the
exact same steps. See [docs/cicd/part-08](../docs/cicd/part-08-fastlane.md) (forthcoming).

Planned files:

| File | Purpose | Part |
|------|---------|------|
| `Fastfile` | lanes: `lint`, `build`, `test`, `beta`, `release`, `screenshots` | 8 |
| `Appfile` | app identifier, Apple ID, team id | 8 |
| `Matchfile` | code-signing via Match (certs/profiles in a private repo) | 9 |
| `Pluginfile` | fastlane plugins | 8 |

> Empty for now — real content arrives in Batch 3.
