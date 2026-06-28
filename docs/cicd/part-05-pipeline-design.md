# Part 5 — Pipeline Design

Part 4 gave us the building blocks and a `ci.yml`. Now we design the **whole** pipeline: every
stage, why it exists, what order it runs in, and how it splits across multiple workflows.

## 5.1 The full pipeline

```
 Developer Push / PR
        │
        ▼
 ┌──────────────┐
 │ Checkout     │  pull the exact commit onto the runner
 ├──────────────┤
 │ Resolve SPM  │  download Swift package dependencies (cached)
 ├──────────────┤
 │ SwiftLint    │  style/correctness rules  ─┐ cheap, fast → run first ("shift left")
 │ SwiftFormat  │  formatting check          ─┘
 ├──────────────┤
 │ Unit Tests   │  XCTest, fast, no UI
 ├──────────────┤
 │ UI Tests     │  XCUITest, slow, simulator-driven   (often parallel matrix)
 ├──────────────┤
 │ Danger       │  PR hygiene: tests added? size? changelog?  (PR only)
 ├──────────────┤  ─────────────  everything above = CI (gates the merge)  ──────────
 │ Archive      │  xcodebuild archive (Release config) → .xcarchive
 ├──────────────┤
 │ Generate IPA │  export signed .ipa from the archive
 ├──────────────┤
 │ Upload       │  store .ipa/.xcresult as artifacts
 │  Artifact    │
 ├──────────────┤
 │ Upload       │  push build to TestFlight via App Store Connect API
 │  TestFlight  │
 ├──────────────┤  ─────────────  everything here = CD (runs after merge)  ──────────
 │ Slack Notify │  "✅ Build 412 on TestFlight" / "❌ build failed: <link>"
 └──────────────┘
```

The **horizontal line** is the key design boundary: stages above run on **every PR** to gate
merges; stages below run **after merge** (or on a tag) to ship.

## 5.2 Why each stage exists

| Stage | Why it exists | Fails the build when… |
|-------|---------------|-----------------------|
| **Checkout** | the runner is empty; it needs your code at the right commit | repo/auth misconfigured |
| **Resolve SPM** | dependencies aren't vendored; must be fetched/pinned | `Package.resolved` can't resolve |
| **SwiftLint** | enforce consistency + catch foot-guns mechanically | a rule is violated (`--strict`) |
| **SwiftFormat** | formatting shouldn't be a review argument | code isn't formatted |
| **Unit tests** | prove logic correctness fast | any XCTest fails |
| **UI tests** | prove user flows still work end-to-end | any XCUITest fails / times out |
| **Danger** | enforce *process* (tests, size, changelog) a linter can't | a Danger `fail()` rule trips |
| **Archive** | produce a distributable Release build | signing/build error |
| **Generate IPA** | TestFlight/App Store need a signed `.ipa`, not an archive | export/signing error |
| **Upload artifact** | keep the exact binary + logs for debugging/audit | (rarely; storage) |
| **Upload TestFlight** | get the build to testers automatically | ASC API/auth/processing error |
| **Notify** | humans need to know the result without watching the tab | (best-effort; `if: always()`) |

**Ordering principle — "shift left / fail fast":** put cheap, fast, frequently-failing checks
(lint, unit) *before* expensive ones (UI tests, archive). A formatting mistake should fail in 60
seconds, not after a 20-minute archive.

## 5.3 Splitting across workflows

One giant workflow with lots of `if:` is hard to reason about. Split by **purpose** (Part 2):

```
.github/workflows/
├── ci.yml        on: PR + feature push     → checkout▶spm▶lint▶unit▶ui▶danger      (the GATE)
├── beta.yml      on: push to develop/main   → ...build▶archive▶ipa▶TestFlight▶notify (CD)
└── release.yml   on: tag v*                 → archive Release▶App Store Connect▶submit (Part 16)
```

Why split:
- **Different triggers** (PR vs merge vs tag).
- **Different secret scope** — `ci.yml` needs almost no secrets; `beta.yml`/`release.yml` need
  signing + App Store Connect keys. Smaller blast radius (Part 23).
- **Different permissions** and runner cost profiles.

## 5.4 `beta.yml` — the CD half (preview)

We'll flesh out signing (Part 9) and TestFlight (Part 15) before this is fully real, but the
shape is:

```yaml
name: Beta (TestFlight)
on:
  push:
    branches: [ "develop" ]        # every merge to develop ships a beta
  workflow_dispatch:                # ...or trigger manually

concurrency:
  group: beta-${{ github.ref }}
  cancel-in-progress: true          # only the latest merge needs to ship

permissions:
  contents: read

jobs:
  beta:
    runs-on: macos-14
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }    # full history → build number from commit count (Part 20)
      - name: Select Xcode
        run: sudo xcode-select -s "/Applications/Xcode_16.0.app"
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }
      - name: Build & upload to TestFlight
        run: bundle exec fastlane beta        # the lane owns archive▶sign▶export▶upload (Part 8)
        env:
          MATCH_PASSWORD:               ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION:${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
          ASC_KEY_ID:                   ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID:                ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8:                   ${{ secrets.ASC_KEY_P8 }}
      - name: Notify Slack
        if: always()                          # report success AND failure
        run: ./Scripts/notify_slack.sh "${{ job.status }}"
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

Notice how **thin** the build step is: `bundle exec fastlane beta`. All the heavy lifting moves
into the Fastlane lane (Part 8) so the same command works on a laptop.

## 5.5 Stage-to-tool map

```
Checkout ........ actions/checkout
Resolve SPM ..... xcodebuild -resolvePackageDependencies (or swift package resolve)
SwiftLint ....... swiftlint
SwiftFormat ..... swiftformat --lint
Unit/UI tests ... xcodebuild test  (via fastlane `scan`)
Danger .......... bundle exec danger
Archive ......... xcodebuild archive (via fastlane `gym`/`build_app`)
IPA ............. -exportArchive    (via fastlane `gym`)
TestFlight ...... fastlane `pilot`/`upload_to_testflight` (ASC API)
Notify .......... curl Slack webhook / slack action
```

## 5.6 Common mistakes
- **Putting UI tests before unit tests/lint.** You wait 20 min to learn a variable was unused.
- **One workflow for everything.** `if:` spaghetti; one job's broad secret scope leaks into all.
- **Archiving on every PR.** Expensive and pointless — archive on merge/tag, validate-build on PRs.
- **Notify only on success.** You won't hear about failures; always `if: always()`.
- **No artifact of the shipped binary.** When TestFlight build 412 misbehaves, you want *that*
  exact `.ipa`/`.xcresult`.

## 5.7 Best practices
- **CI gates, CD ships** — keep the boundary explicit, split into separate workflows.
- **Fail fast, parallel-where-independent, serialize-only-with-`needs`.**
- **Make the build step a single Fastlane lane** so local == CI.
- **Cancel superseded runs** on busy branches.
- **Every shipped build = an artifact** tied to a commit/tag (auditability + rollback, Part 18).

---

**Next:** [Part 6 — GitHub-Hosted Runners](part-06-runners.md): why macOS is mandatory, how Xcode
and simulators are provided, the clean-VM lifecycle, limits, and the billing math that drives a lot
of these design choices.
