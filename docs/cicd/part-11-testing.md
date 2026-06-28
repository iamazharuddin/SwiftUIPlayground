# Part 11 — Testing in CI

Tests are the heart of CI: they're what turns "it compiles" into "it works." This part covers the
test *types*, how `xcodebuild`/Fastlane run them, code coverage, parallelism, and how results
surface on the PR.

## 11.1 The test pyramid (and what each costs)

```
            ╱╲          UI tests (XCUITest)        slow, flaky-prone, few
           ╱  ╲         — drive the real app via the Simulator
          ╱────╲        Integration tests          medium
         ╱      ╲       — multiple units + real-ish deps (network stubs, DB)
        ╱────────╲      Unit tests (XCTest)         fast, many, run on every push
       ╱──────────╲     — pure logic: ViewModels, mappers, formatters
      ╱────────────╲    Snapshot tests              fast-ish, catch UI regressions
```

**Design rule:** lots of fast unit tests, fewer integration, a thin layer of UI tests for critical
flows. In CI: **unit tests on every push** (fast feedback), **UI tests on PR/merge** (they're slow).

## 11.2 The types

### Unit tests (XCTest)
Pure logic, no UI, no network. The MVVM payoff: ViewModels are testable without a screen.
```swift
func test_login_disablesButton_whenEmailInvalid() {
    let vm = LoginViewModel()
    vm.email = "not-an-email"
    XCTAssertFalse(vm.isSubmitEnabled)
}
```
Fast (ms each) → run thousands on every push.

### UI tests (XCUITest)
Launch the app in the Simulator and tap/assert like a user.
```swift
func test_login_flow() {
    let app = XCUIApplication(); app.launch()
    app.textFields["email"].tap(); app.typeText("a@b.com")
    app.buttons["Continue"].tap()
    XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
}
```
Slow (seconds–minutes), simulator-dependent, more flaky → keep few, run later in the pipeline.

### Snapshot tests
Render a view, compare against a stored reference image; fail on pixel diff. Catch unintended UI
changes cheaply. (Libraries like swift-snapshot-testing.) **Gotcha:** reference images are
rendering-environment-sensitive — pin the **simulator device + OS** so CI matches where references
were recorded, or they'll false-fail.

### Integration tests
Exercise several components together with realistic (but controlled) dependencies — e.g. a
repository hitting a **stubbed** network layer. They catch wiring bugs unit tests miss.

## 11.3 Running them — `xcodebuild` / Fastlane `scan`

Raw (Part 7):
```bash
set -o pipefail
xcodebuild test \
  -project App/App.xcodeproj -scheme ProductionApp-QA \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5" \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult | xcbeautify
```
Via Fastlane (what our Fastfile uses):
```ruby
run_tests(
  scheme: "ProductionApp-QA",
  devices: ["iPhone 15"],
  result_bundle: true,        # → .xcresult
  code_coverage: true,
  only_testing: ["AppTests"]  # e.g. unit-only on PRs; add UITests on merge
)
```

Split slow from fast with `only_testing:` / `skip_testing:`:
```
PR push   → only_testing: ["AppTests"]                 (unit only, ~minutes)
merge     → full suite incl. ["AppUITests"]            (unit + UI)
```

## 11.4 Code coverage

`-enableCodeCoverage YES` / `code_coverage: true` records which lines ran. Extract it from the
`.xcresult`:
```bash
xcrun xccov view --report --json TestResults.xcresult > coverage.json
# or use a tool/plugin to produce a % and a per-file breakdown
```
Use it to:
- **Report** coverage % on the PR (Danger can comment it — Part 12).
- **Gate** (carefully): "new code must be ≥ 80% covered." Prefer gating *changed* files over a
  global number — a blunt global threshold punishes unrelated work.

> Coverage measures *executed* lines, not *asserted* behavior. 90% coverage with weak assertions is
> a false sense of safety. Treat it as a signal, not a target to game.

## 11.5 Parallel testing (speed; Part 22)

Two complementary levers:

**Parallel destinations via matrix** — fan one job into many runners:
```yaml
strategy:
  fail-fast: false
  matrix:
    destination:
      - "platform=iOS Simulator,name=iPhone 15,OS=17.5"
      - "platform=iOS Simulator,name=iPhone SE (3rd generation),OS=16.4"
```

**Parallel simulators on one runner** — Xcode can clone the sim and shard:
```ruby
run_tests(parallel_testing: true, concurrent_workers: 3)
```
Tradeoff: more parallelism = faster wall-clock but more macOS minutes and more flakiness surface.

## 11.6 Test reports on the PR

```
xcodebuild test ─▶ TestResults.xcresult ─┬─▶ upload-artifact  (downloadable bundle, Part 14)
                                         ├─▶ xcresulttool → JUnit/Markdown → PR check annotations
                                         └─▶ xccov → coverage % → Danger comment (Part 12)
```
The goal: a reviewer sees **"42 passed, 1 failed (LoginVMTests.test_invalidEmail), coverage 81%"**
on the PR without opening Xcode.

## 11.7 Common mistakes
- **Piping without `set -o pipefail`** → failing tests show green (said it before; it's the #1
  iOS-CI bug).
- **UI tests on every push** → slow pipelines; people stop waiting. Gate them to PR/merge.
- **Flaky tests left red** → trains the team to ignore failures. Quarantine + fix; flaky == broken.
- **Snapshot tests without a pinned simulator** → false diffs across Xcode/OS versions.
- **Chasing a global coverage number** → busywork tests; gate changed files instead.
- **No `.xcresult` artifact** → "it failed in CI" with nothing to inspect.

## 11.8 Debugging
- Download the `.xcresult` artifact, open in Xcode → exact failure, logs, and for UI tests
  **screenshots/video** at the failing step.
- Re-run only the failing test: `-only-testing:AppTests/LoginVMTests/test_invalidEmail`.
- Flaky UI test → add `waitForExistence`, stabilize animations (`UIView.setAnimationsEnabled(false)`
  in UI-test builds), reduce shared state.
- Reproduce with the **same simulator device+OS** CI uses (`xcrun simctl list`).

## 11.9 Best practices
- **Fast unit tests everywhere; thin, stable UI layer for critical flows.**
- **Shard fast/slow by trigger** (unit on push, full on merge).
- **Always `result_bundle: true`** and upload it.
- **Coverage as a signal**, gate on changed files if at all.
- **Zero-tolerance for flakiness** — a quarantined-and-tracked flaky test beats a randomly-red
  pipeline.
- **Pin the simulator** (device + OS) for determinism, especially snapshots.

---

**Next:** [Part 12 — Static Analysis](part-12-static-analysis.md): SwiftLint, SwiftFormat, and
Danger — the checks that fail your build for style and process, with real config files.
