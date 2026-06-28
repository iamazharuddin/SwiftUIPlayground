# Part 4 — GitHub Actions, keyword by keyword

This is the reference you'll come back to. We tour every keyword you'll use, explain what it does
*and what GitHub does internally* for it, then assemble the **first real `ci.yml`** at the end.

## 4.1 The mental model

A **workflow** (one `.yml` file) contains **jobs**. Each job runs on its own **runner** (a fresh
VM) and contains **steps**. A step either **`uses:`** a prebuilt action or **`run:`s** a shell
command.

```
workflow (ci.yml)
├── job: lint        ── runner A ── steps: [checkout, swiftlint]
├── job: test        ── runner B ── steps: [checkout, cache, xcodebuild test]
└── job: danger      ── runner C ── steps: [checkout, bundle, danger]   (needs: [lint,test])
```

## 4.2 Top-level keywords

### `name`
Human label for the workflow, shown in the Actions tab. Cosmetic but do it.
```yaml
name: CI
```

### `on` — the trigger (Part 2 explained the event flow)
Declares which events start this workflow. Filters narrow it down.
```yaml
on:
  push:
    branches: [ "develop", "feature/**" ]   # only these branches
    paths-ignore: [ "docs/**", "**.md" ]      # skip runs for docs-only changes
  pull_request:
    branches: [ "develop", "main" ]
  workflow_dispatch:                           # adds a manual "Run workflow" button
```
*Internals:* GitHub evaluates these filters against the event; non-matching events create **no
run at all** (not a skipped run — literally nothing). `paths-ignore` is how you avoid burning
expensive macOS minutes on README edits.

### `permissions` — least privilege (Part 23)
Sets what the automatic `GITHUB_TOKEN` may do. Default is broad; tighten it.
```yaml
permissions:
  contents: read          # clone the repo
  pull-requests: write    # let Danger post PR comments
```
*Why:* if a step is compromised, it can only do what you granted. Start at `read` and add the
minimum.

### `concurrency` — cancel superseded runs
```yaml
concurrency:
  group: ci-${{ github.ref }}      # one group per branch/PR
  cancel-in-progress: true          # new push cancels the old, still-running build
```
*Why it matters for iOS:* macOS minutes cost ~10× Linux. If you push 3 times in 5 minutes, you
don't want 3 full builds running — cancel the stale ones.

### `env` — workflow-wide variables
```yaml
env:
  XCODE_VERSION: "16.0"
  SCHEME: "ProductionApp-QA"
```
Available to every job/step as `$SCHEME` / `${{ env.SCHEME }}`. Job- and step-level `env:` override
it.

## 4.3 Inside `jobs:`

### `runs-on` — pick the machine
```yaml
runs-on: macos-14      # a GitHub-hosted macOS 14 runner (required for Xcode; Part 6)
```

### `needs` — dependencies / ordering
By default jobs run **in parallel**. `needs:` serializes them and forms a DAG.
```yaml
jobs:
  lint:   { runs-on: macos-14, steps: [...] }
  test:   { runs-on: macos-14, steps: [...] }
  danger:
    needs: [ lint, test ]   # runs only after BOTH succeed
    runs-on: macos-14
```
*Internals:* a job whose `needs` failed is skipped; the scheduler won't provision a runner for it.

### `if` — conditional execution
```yaml
if: github.ref == 'refs/heads/develop'        # job/step runs only on develop
if: ${{ github.event_name == 'pull_request' }}
if: always()                                   # run even if a previous step failed (e.g. upload logs)
```

### `strategy` + `matrix` — fan-out
Expands one job into N parallel jobs, one per combination.
```yaml
strategy:
  fail-fast: false                  # one combo failing doesn't cancel the others
  matrix:
    destination:
      - "platform=iOS Simulator,name=iPhone 15,OS=17.5"
      - "platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5"
```
Each `matrix.destination` becomes its own runner/job. Great for testing across devices/OS
versions (Part 11/22).

### `timeout-minutes` — kill stuck jobs
```yaml
timeout-minutes: 30     # iOS builds hang sometimes (simulator deadlocks); cap the bleeding
```
Default is 360 (6h) — far too long when each minute costs money. Always set this.

### `outputs` — pass values to downstream jobs
A job can publish outputs that `needs`-dependent jobs read.
```yaml
jobs:
  version:
    runs-on: macos-14
    outputs:
      build_number: ${{ steps.bump.outputs.build_number }}
    steps:
      - id: bump
        run: echo "build_number=412" >> "$GITHUB_OUTPUT"
  beta:
    needs: version
    runs-on: macos-14
    steps:
      - run: echo "Building ${{ needs.version.outputs.build_number }}"
```
*Internals:* writing `key=value` to the `$GITHUB_OUTPUT` file is how a step exports a value;
GitHub captures it.

## 4.4 Inside `steps:`

### `uses` + `with` — call a prebuilt action
```yaml
- name: Checkout
  uses: actions/checkout@v4         # a reusable action (pin to SHA in prod; Part 23)
  with:                              # inputs to that action
    fetch-depth: 0                   # full history (needed for versioning by commit count)
```
*Internals:* an action is just a repo containing code (JS or a Docker/composite definition).
`uses:` fetches and runs it. `@v4` is a tag; for security pin to a commit SHA.

### `run` — execute shell
```yaml
- name: SwiftLint
  run: |                             # multi-line shell; runs in bash on macOS runners
    brew install swiftlint
    swiftlint --strict               # nonzero exit ⇒ step fails ⇒ job fails
  shell: bash
  working-directory: App             # cd here first
```
*Internals:* each `run:` is a script; **a nonzero exit code fails the step**, which fails the job,
which (if required) fails the PR check. This is the whole pass/fail mechanism.

### `env` at step level, and `secrets`
```yaml
- name: Upload to TestFlight
  run: bundle exec fastlane beta
  env:
    APP_STORE_CONNECT_KEY: ${{ secrets.APP_STORE_CONNECT_KEY }}   # injected, masked in logs
```
*Internals:* `secrets.*` values are decrypted into the job's env at runtime and **auto-masked** in
logs (they print as `***`). Secrets are **not** available to `pull_request` runs from forks
(Part 2/10).

### `cache` — persist between runs (Part 13)
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/Library/Developer/Xcode/DerivedData
      ~/Library/Caches/org.swift.swiftpm
    key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
    restore-keys: spm-${{ runner.os }}-
```
`key` identifies the cache; if `Package.resolved` is unchanged the runner restores SPM downloads
instead of re-fetching. (Deep dive in Part 13.)

### Artifacts — persist outputs (Part 14)
```yaml
- uses: actions/upload-artifact@v4
  if: always()                       # upload logs even on failure
  with:
    name: test-results
    path: fastlane/test_output/**
    retention-days: 14
```

## 4.5 Useful context expressions

`${{ ... }}` is the expression syntax. The objects you'll use most:

| Expression | Is |
|---|---|
| `github.ref` | the ref, e.g. `refs/heads/develop` or `refs/tags/v1.4.0` |
| `github.sha` | the commit SHA |
| `github.event_name` | `push`, `pull_request`, … |
| `github.run_number` | incrementing run counter (handy for build numbers) |
| `runner.os` | `macOS` |
| `secrets.NAME` | a repo/org/environment secret |
| `needs.<job>.outputs.<k>` | output from a dependency job |

## 4.6 The first real `ci.yml`

This is committed at [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) with the same
comments. It runs on PRs and feature pushes: lint → (build+unit test) → Danger.

```yaml
name: CI

on:
  push:
    branches: [ "feature/**", "bugfix/**", "develop" ]
    paths-ignore: [ "docs/**", "**.md" ]
  pull_request:
    branches: [ "develop", "main" ]

# Cancel an in-flight run when a newer commit lands on the same branch/PR.
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

# Least privilege: read the code; let Danger comment on PRs.
permissions:
  contents: read
  pull-requests: write

env:
  XCODE_VERSION: "16.0"
  SCHEME: "ProductionApp-QA"        # QA scheme builds against QA.xcconfig (Part 19)
  DESTINATION: "platform=iOS Simulator,name=iPhone 15,OS=17.5"

jobs:
  # ---------- 1) Fast, cheap check first: lint ----------
  lint:
    runs-on: macos-14
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s "/Applications/Xcode_${XCODE_VERSION}.app"
      - name: SwiftLint
        run: |
          brew install swiftlint
          swiftlint --strict          # warnings become errors → fail fast

  # ---------- 2) Build + unit tests (parallel with lint) ----------
  unit_test:
    runs-on: macos-14
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s "/Applications/Xcode_${XCODE_VERSION}.app"
      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
          key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
          restore-keys: spm-${{ runner.os }}-
      - name: Build & test
        run: |
          set -o pipefail
          xcodebuild test \
            -project App/App.xcodeproj \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            -resultBundlePath TestResults.xcresult \
            | xcbeautify              # prettify logs; pipefail keeps real exit code
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: unit-test-results
          path: TestResults.xcresult
          retention-days: 14

  # ---------- 3) Danger: only on PRs, after lint+test ----------
  danger:
    needs: [ lint, unit_test ]
    if: github.event_name == 'pull_request'
    runs-on: macos-14
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }     # installs Gemfile + caches gems
      - name: Run Danger
        run: bundle exec danger
        env:
          DANGER_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Line-by-line of the non-obvious bits
- **`concurrency` / `cancel-in-progress`** — saves macOS minutes on rapid pushes.
- **`paths-ignore`** — a docs-only PR won't spin up a Mac.
- **lint and unit_test have no `needs`** → they run **in parallel**, so you get lint feedback
  without waiting for the build.
- **`set -o pipefail` + `| xcbeautify`** — piping to a formatter normally hides `xcodebuild`'s
  exit code; `pipefail` ensures a test failure still fails the step.
- **`-resultBundlePath`** — emits an `.xcresult` we upload as an artifact for inspecting failures
  (Part 14).
- **`danger` job** — gated to PRs and to *after* lint+test, uses the built-in `GITHUB_TOKEN` to
  comment.

## 4.7 Common mistakes
- **No `timeout-minutes`** → a hung simulator burns 6h of paid minutes.
- **Piping `xcodebuild` without `pipefail`** → green pipeline that actually had failing tests.
- **Relying on job order without `needs`** → race conditions.
- **Using `@main` / moving tags for actions** → supply-chain risk and surprise breakage; pin SHAs.
- **Granting `permissions: write-all`** → over-privileged token.

## 4.8 Best practices
- **Cheapest checks first**, parallel where independent; expensive/serial only via `needs`.
- **Pin Xcode** explicitly (`xcode-select`) — runner image defaults drift over time.
- **Pin action versions to SHAs** in production repos.
- **Tighten `permissions`** per workflow; default to `contents: read`.
- **Always upload `.xcresult`/logs** with `if: always()` so failures are debuggable.

---

**Next:** [Part 5 — Pipeline Design](part-05-pipeline-design.md): turning these keywords into the
full lint→test→danger→archive→ipa→TestFlight→notify pipeline, split across `ci.yml` / `beta.yml`.
