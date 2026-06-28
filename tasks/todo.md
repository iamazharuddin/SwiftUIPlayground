# iOS CI/CD Masterclass (GitHub Actions) — Plan

**Goal:** A production-grade, beginner→advanced iOS CI/CD masterclass using GitHub Actions,
delivered as (a) structured Markdown docs under `docs/cicd/` and (b) real, working,
heavily-commented pipeline files at their natural repo locations.

**Running example:** hypothetical production app — Swift / SwiftUI / UIKit / MVVM / SPM,
multiple targets, schemes Dev / QA / Staging / Production, hosted on GitHub.

**Teaching style (per topic):** concept → why → where it fits → ASCII diagram →
real config/code → line-by-line → internals → common mistakes → debugging → best practices.

**Pacing:** incremental batches; user reviews and says "continue".

---

## Deliverable layout

```
docs/cicd/
  README.md                      # index / table of contents
  part-01-cicd-fundamentals.md
  part-02-github-internals.md
  part-03-repository-structure.md
  ... (one file per part)
.github/workflows/               # real workflows (Parts 4–5, 21–22)
fastlane/                        # real Fastfile/Appfile/Matchfile (Parts 8–9)
Configurations/                  # real .xcconfig per env (Part 19)
Scripts/                         # real helper scripts
Gemfile                          # Ruby deps (Part 8)
Dangerfile                       # PR automation (Parts 12, 21)
```

---

## Parts checklist

- [x] Plan written, scope confirmed (docs+files, incremental, hypothetical app)
- [ ] **Batch 1 (now):** Part 1 Fundamentals · Part 2 GitHub internals · Part 3 Repo structure (+ folder skeleton)
- [x] **Batch 2:** Part 4 GitHub Actions keywords (+ real `ci.yml`) · Part 5 Pipeline design · Part 6 Runners
- [x] **Batch 3:** Part 7 Build process · Part 8 Fastlane (+ real `fastlane/` files, `Gemfile`) · Part 9 Code signing
- [x] **Batch 4:** Part 10 Secrets (+ `decode_secrets.sh`) · Part 11 Testing · Part 12 Static analysis (+ `.swiftlint.yml`, `.swiftformat`, `Dangerfile`)
- [x] **Batch 5:** Part 13 Caching · Part 14 Artifacts · Part 15 TestFlight (+ real `beta.yml`, `notify_slack.sh`)
- [x] **Batch 6:** Part 16 App Store release (+ real `release.yml`) · Part 17 Notifications · Part 18 Rollback
- [x] **Batch 7:** Part 19 Environments/xcconfig (+ 5 `.xcconfig`) · Part 20 Versioning (+ `set_build_number.sh`) · Part 21 PR automation (+ `CODEOWNERS`)
- [x] **Batch 8:** Part 22 Performance (+ `setup-ios` composite action) · Part 23 Security · Part 24 Enterprise workflow
- [x] All 24 parts complete

---

## Review

**COMPLETE — all 24 parts + real pipeline files delivered.**

- `docs/cicd/` — index + Parts 1–24 (~3,850 lines), each: concept → why → where → diagram →
  config → line-by-line → internals → mistakes → debugging → best practices.
- Real files (production-shaped, hypothetical app):
  - Workflows: `.github/workflows/ci.yml`, `beta.yml`, `release.yml`
  - Composite action: `.github/actions/setup-ios/action.yml`
  - `.github/CODEOWNERS`
  - Fastlane: `fastlane/{Fastfile,Appfile,Matchfile,Pluginfile}` + `Gemfile`
  - Config: `Configurations/{Base,Dev,QA,Staging,Production}.xcconfig`
  - Static analysis: `.swiftlint.yml`, `.swiftformat`, `Dangerfile`
  - Scripts: `Scripts/{decode_secrets,notify_slack,set_build_number}.sh`
- Pipeline files carry headers noting they target a hypothetical multi-scheme app and need
  project/scheme/secrets wiring before they run against a real target.
- Note: Parts 1–3 + UI library/skill were merged earlier in PR #4; Parts 4–24 are uncommitted on
  `docs/readme-description` (not yet PR'd).
