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
- [ ] **Batch 6:** Part 16 App Store release · Part 17 Notifications · Part 18 Rollback
- [ ] **Batch 7:** Part 19 Environments/xcconfig · Part 20 Versioning · Part 21 PR automation
- [ ] **Batch 8:** Part 22 Performance · Part 23 Security · Part 24 Enterprise workflow
- [ ] Final pass: wire workflows end-to-end, fill review section

---

## Review

### Batch 1 (Parts 1–3)
- Created `docs/cicd/README.md` (index) + Parts 1–3 docs.
- Scaffolded real folder skeleton: `.github/workflows/`, `fastlane/`, `Configurations/`, `Scripts/`
  each with a README explaining its purpose (content filled in later batches).
- Next: say "continue" for Batch 2 (Actions keywords, pipeline design, runners).
