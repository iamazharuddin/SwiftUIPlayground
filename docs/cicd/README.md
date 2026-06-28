# iOS CI/CD Masterclass — GitHub Actions

A production-grade, beginner→advanced guide to building a real CI/CD pipeline for an iOS app
on **GitHub Actions**, written for an experienced iOS engineer with little DevOps background.

**Running example app:** Swift · SwiftUI · UIKit · MVVM · Swift Package Manager · multiple
targets · schemes **Dev / QA / Staging / Production** · hosted on GitHub.

## How this is organized

Each "Part" is a standalone doc. Concepts build on each other, so read in order the first time.
Every topic follows the same shape:

1. **Concept** — what it is, in plain terms
2. **Why it exists** — the problem it solves
3. **Where it fits** — its place in the pipeline
4. **Diagram** — ASCII flow
5. **Real config/code** — copy-pasteable
6. **Line-by-line** — every line explained
7. **Internals** — what actually happens under the hood
8. **Common mistakes**
9. **Debugging**
10. **Best practices** used by senior engineers

## Table of contents

| Part | Topic | Status |
|------|-------|--------|
| 1 | [CI/CD Fundamentals](part-01-cicd-fundamentals.md) | ✅ |
| 2 | [GitHub Internals — push → Actions](part-02-github-internals.md) | ✅ |
| 3 | [Repository Structure](part-03-repository-structure.md) | ✅ |
| 4 | GitHub Actions keywords | ⏳ |
| 5 | Pipeline design | ⏳ |
| 6 | GitHub-hosted runners | ⏳ |
| 7 | The build process (xcodebuild) | ⏳ |
| 8 | Fastlane (beginner→advanced) | ⏳ |
| 9 | Code signing & Match | ⏳ |
| 10 | Secrets management | ⏳ |
| 11 | Testing | ⏳ |
| 12 | Static analysis (SwiftLint/Danger) | ⏳ |
| 13 | Caching | ⏳ |
| 14 | Artifacts | ⏳ |
| 15 | TestFlight deployment | ⏳ |
| 16 | App Store release | ⏳ |
| 17 | Notifications (Slack/Teams/Email) | ⏳ |
| 18 | Rollback strategy | ⏳ |
| 19 | Environment management (xcconfig) | ⏳ |
| 20 | Versioning | ⏳ |
| 21 | Pull Request automation | ⏳ |
| 22 | Performance optimization | ⏳ |
| 23 | Security | ⏳ |
| 24 | Real enterprise workflow | ⏳ |

## The whole pipeline at a glance

```
 Developer                         GitHub Cloud                       Apple
 ─────────                         ────────────                       ─────
  git push ──┐
             │   ┌──────────────────────────────────────────────┐
  open PR ───┼──▶│  Event ▶ Actions ▶ macOS runner              │
             │   │     resolve SPM ▶ lint ▶ test ▶ danger        │
  merge ─────┘   │     ▶ archive ▶ export .ipa ▶ sign (Match)    │──▶ App Store
                 │     ▶ upload TestFlight ▶ notify Slack        │    Connect
                 └──────────────────────────────────────────────┘     │
                                                                       ▼
                                                              TestFlight / Review
```

Real pipeline files live at the repo root (`.github/workflows/`, `fastlane/`,
`Configurations/`, `Scripts/`, `Gemfile`, `Dangerfile`) and are introduced in the
Parts that build them.
