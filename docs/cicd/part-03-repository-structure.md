# Part 3 — Repository Structure

A production iOS repo is more than the Xcode project. The CI/CD machinery — build scripts,
signing config, environment files, PR automation — lives in well-known folders so both humans and
the pipeline can find them. This part designs that layout and explains **why each folder exists**.

> The real skeleton for these folders has been scaffolded at this repo's root (`.github/`,
> `fastlane/`, `Configurations/`, `Scripts/`), each with a README. Later Parts fill them with real
> content.

## 3.1 The target layout

```
ProductionApp/
├── App/                      # the Xcode project + Swift source
│   ├── App.xcodeproj         #   (or .xcworkspace if using CocoaPods/SPM workspace)
│   ├── Sources/              #   app code (MVVM: Models, ViewModels, Views, Services)
│   ├── Resources/            #   assets, Info.plist(s), Localizable.strings
│   └── Tests/                #   AppTests (unit), AppUITests (UI)
│
├── Configurations/           # .xcconfig files — one per environment (Part 19)
│   ├── Base.xcconfig
│   ├── Dev.xcconfig
│   ├── QA.xcconfig
│   ├── Staging.xcconfig
│   └── Production.xcconfig
│
├── fastlane/                 # the automation brain (Part 8)
│   ├── Fastfile              #   lanes: lint, build, test, beta, release
│   ├── Appfile               #   bundle id, Apple ID, team id
│   ├── Matchfile             #   code-signing (Match) config (Part 9)
│   └── Pluginfile            #   fastlane plugins
│
├── Scripts/                  # standalone shell/ruby helpers
│   ├── bootstrap.sh          #   install tooling (mise/brew, bundler, etc.)
│   ├── set_build_number.sh   #   versioning helper (Part 20)
│   └── decode_secrets.sh     #   materialize base64 secrets at runtime (Part 10)
│
├── .github/
│   └── workflows/            # GitHub Actions workflows (Parts 4–5)
│       ├── ci.yml            #   PR + branch validation
│       ├── beta.yml          #   merge → TestFlight
│       └── release.yml       #   tag → App Store
│
├── Dangerfile                # PR-automation rules (Parts 12, 21)
├── Gemfile                   # Ruby deps: fastlane, danger, cocoapods (Part 8)
├── Gemfile.lock              # pinned versions → reproducible tooling
├── .swiftlint.yml            # lint rules (Part 12)
├── .swiftformat              # format rules (Part 12)
├── mise.toml / .ruby-version # pinned Ruby/tool versions
└── README.md
```

## 3.2 Why each folder exists

### `App/`
The actual product. Separating it into its own folder keeps the repo root readable and makes it
obvious that everything *outside* `App/` is tooling. Inside, an MVVM layout
(`Models/ViewModels/Views/Services`) plus `Tests/` keeps source and tests adjacent.

*Why it matters for CI:* the workflow needs a **stable, known path** to the `.xcodeproj`/scheme.
If the project moves, every `xcodebuild` invocation breaks.

### `Configurations/` (`.xcconfig`)
Build settings as plain text files, one per environment. Instead of clicking through Xcode's build
settings (invisible to code review), settings like `API_BASE_URL`, `BUNDLE_ID_SUFFIX`,
`PRODUCT_NAME`, and feature flags live in version-controlled `.xcconfig` files.

*Why:* environments (Dev/QA/Staging/Production) differ only by these values. Text files are
diffable, reviewable, and let CI pick an environment by pointing a scheme at the right
`.xcconfig`. (Full treatment in Part 19.)

### `fastlane/`
The **single source of truth for build logic.** A `Fastfile` defines *lanes* — named sequences of
steps (`lint`, `test`, `beta`, `release`). Both a developer on their laptop and the CI runner call
the **same lane** (`bundle exec fastlane beta`), so behavior is identical everywhere.

*Why:* without it, build logic gets duplicated — some in the YAML, some in a script, some in a
senior dev's head. Centralizing in lanes kills "works in CI but not locally." (Part 8.)

### `Scripts/`
Small, focused shell/Ruby scripts for things that aren't worth a Fastlane action: bootstrapping
tools, decoding secrets into files at runtime, bumping build numbers. Keeping them as files (not
inline YAML `run:` blobs) makes them testable locally and reusable across workflows.

### `.github/workflows/`
Where GitHub looks for pipelines (Part 2). Splitting into `ci.yml` / `beta.yml` / `release.yml`
maps one workflow to one purpose, so each can have its own triggers, permissions, and secrets
scope. `.github/` can also hold `CODEOWNERS`, PR templates, and Dependabot config.

### `Dangerfile`
Rules for **PR automation** run by [Danger](https://danger.systems). On each PR it can comment
"you changed code but added no tests," "PR is 2,000 lines — split it," "you bumped the version but
didn't update the changelog," and **fail the check** to block merge. Lives at root by convention.
(Parts 12, 21.)

### `Gemfile` / `Gemfile.lock`
iOS tooling (fastlane, danger, cocoapods) is Ruby. The `Gemfile` declares them; the **`.lock` file
pins exact versions** so CI installs the *same* fastlane your teammate has. `bundle exec`
guarantees the pinned versions are used.

*Why the lock matters:* without it, CI might silently pull a newer fastlane that changes behavior —
a classic "the pipeline broke and nobody changed anything" cause.

### Root dotfiles (`.swiftlint.yml`, `.swiftformat`, `mise.toml`)
Tool configs live at root so the tools auto-discover them and so they apply repo-wide. Pinning
tool versions (Ruby, Xcode via `mise`/`.xcode-version`) makes builds reproducible across machines
and across time.

## 3.3 Diagram — who reads what

```
            ┌─────────────────── .github/workflows/*.yml ──────────────────┐
            │  triggers: push / PR / tag                                    │
            │  each job calls ▼                                             │
            │            bundle exec fastlane <lane>                        │
            └──────────────────────────┬───────────────────────────────────┘
                                        ▼
                                  fastlane/Fastfile
                                  ├─ reads Appfile (ids)
                                  ├─ reads Matchfile (signing)        ─▶ Configurations/*.xcconfig
                                  ├─ runs Scripts/*.sh                       (env values)
                                  ├─ runs SwiftLint (.swiftlint.yml)
                                  ├─ runs Danger   (Dangerfile)
                                  └─ runs xcodebuild on App/App.xcodeproj
```

The takeaway: **the YAML is thin** (it decides *when* and *on what machine*), and **Fastlane is
thick** (it decides *how to build*). Everything else is config the Fastfile reads.

## 3.4 Common mistakes

- **Build logic in YAML instead of Fastlane.** Leads to duplication and un-runnable-locally
  pipelines. Keep YAML to "checkout, cache, call lane."
- **No `Gemfile.lock` committed.** Non-reproducible tooling; "works on my fastlane version."
- **Secrets/certs committed** under `Certificates/` in plain form. Never. Match stores encrypted
  certs in a *separate private repo* (Part 9); secrets live in GitHub Secrets (Part 10).
- **Environment differences hardcoded in Swift** (`if isQA`). Push them into `.xcconfig` +
  schemes so the binary is configured at build time, not littered with branches.

## 3.5 Best practices

- **Root = tooling, `App/` = product.** A newcomer should understand the repo's shape in 10
  seconds.
- **Pin everything** (Ruby gems, Xcode version, action SHAs) → reproducible builds.
- **One lane = one job's "how."** The workflow names the *when*; the lane owns the *how*.
- **Treat `Configurations/` as the only place environment values live**, so adding "Staging-EU"
  later is a new `.xcconfig`, not a code change.

---

**Next:** [Part 4 — GitHub Actions keywords](part-04-github-actions.md): a line-by-line tour of
`name`, `on`, `jobs`, `needs`, `matrix`, `concurrency`, `permissions`, `secrets`, `cache`, and
more — then we write the first real `ci.yml`.
