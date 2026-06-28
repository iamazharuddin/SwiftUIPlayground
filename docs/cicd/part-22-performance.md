# Part 22 — Performance Optimization

Slow pipelines cost two things: **money** (macOS minutes, Part 6) and **focus** (long feedback
loops make people context-switch, Part 1). This part covers every lever to make CI fast and cheap,
plus a real **composite action** to kill repetition.

## 22.1 Where the time goes (profile first)

```
 typical cold iOS PR build (~12 min)
 ├─ provision runner + checkout      ~30s
 ├─ resolve + download SPM           ~3m     ← cache (Part 13)
 ├─ build dependencies               ~3m     ← cache / prebuild
 ├─ compile app + tests              ~4m     ← parallelize, incremental
 └─ run tests                        ~2m     ← shard, only-testing
```
**Rule:** measure before optimizing. The Actions UI shows per-step timing; attack the biggest bar,
not the easiest one.

## 22.2 The levers

### 1) Caching (Part 13) — biggest, cheapest win
Cache SPM + gems keyed by lockfiles → a 12-min cold build becomes ~5-min warm. Do this first.

### 2) Parallel jobs (Part 4 `needs`)
Independent jobs run on separate runners simultaneously. lint ∥ unit_test (no `needs`) already
overlaps; only serialize what truly depends (danger `needs: [lint, unit_test]`).
```
 serial:    lint→build→test→danger     = sum of all
 parallel:  lint ∥ (build→test) → danger = max, not sum
```

### 3) Matrix builds (Part 4) — fan-out
Test across devices/OS in parallel instead of sequentially:
```yaml
strategy:
  fail-fast: false
  matrix:
    destination: [ "…iPhone 15,OS=17.5", "…iPhone SE,OS=16.4" ]
```
Wall-clock = one device's time, not the sum. Cost: more macOS minutes (tradeoff).

### 4) Test sharding & scoping (Part 11)
`only_testing:` unit on PRs, full suite on merge; `parallel_testing: true` to use multiple
simulators on one runner.

### 5) Incremental builds
On **self-hosted** runners (Part 6), DerivedData stays warm → only changed files recompile (huge).
On hosted runners you start cold each time; cache narrows but can't fully close the gap → this is a
top reason orgs move to self-hosted Macs at scale.

### 6) Job dependencies & artifact reuse
Don't rebuild what a prior job already produced. Archive once, **upload artifact** (Part 14), let
downstream jobs **download** it instead of re-archiving (especially to move a file to a cheap Linux
job).

### 7) Right-size runners (Part 6)
macOS only where Xcode is needed. Move JSON/lint/Slack/Danger-only work to `ubuntu-latest` (≈1/10
the cost). Larger/faster macOS runner SKUs cost more per minute but can finish faster — measure
cost-per-build, not cost-per-minute.

### 8) Cancel superseded runs (Part 4)
`concurrency: cancel-in-progress: true` — don't pay for stale builds on rapid pushes.

### 9) Skip needless runs
`paths-ignore` for docs; `if:` guards so heavy jobs (archive) run only on merge/tag, not every PR.

## 22.3 Composite Actions & reusable workflows — kill repetition

Every job repeats "checkout → select Xcode → setup ruby → cache." Extract it once.

### Composite action (committed)
[`.github/actions/setup-ios/action.yml`](../../.github/actions/setup-ios/action.yml):
```yaml
name: "Setup iOS build env"
description: "Checkout deps already done by caller; selects Xcode, sets up Ruby+bundler, caches SPM"
inputs:
  xcode-version: { description: "Xcode version", required: false, default: "16.0" }
runs:
  using: "composite"
  steps:
    - name: Select Xcode
      shell: bash
      run: sudo xcode-select -s "/Applications/Xcode_${{ inputs.xcode-version }}.app"
    - uses: ruby/setup-ruby@v1
      with: { bundler-cache: true }
    - name: Cache SPM
      uses: actions/cache@v4
      with:
        path: ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
        key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
        restore-keys: spm-${{ runner.os }}-
```
Used in any workflow:
```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/setup-ios
    with: { xcode-version: "16.0" }
  - run: bundle exec fastlane test
```
One change to the setup → every workflow benefits. (**Reusable workflows** — `workflow_call` — do
the same at the whole-job level for sharing across repos.)

## 22.4 Common mistakes
- **Optimizing without profiling** → you speed up a 20s step and ignore the 4m one.
- **Over-parallelizing** → more macOS minutes + more flakiness than the time saved is worth.
- **Caching DerivedData carelessly** → stale-cache build failures cost more than they save (Part 13).
- **Running everything on macOS** → paying 10× for Linux-able work.
- **No `cancel-in-progress`** → 3 stale builds running per busy branch.
- **Copy-pasted setup across workflows** → drift; fix it once with a composite action.

## 22.5 Debugging / measuring
- Per-step timing in the Actions UI; download the timing or use the run summary.
- Compare cold vs warm: check the cache step's "restored/created" lines (Part 13).
- A/B a change on the same PR by re-running and comparing durations.
- Track **cost-per-build** (minutes × rate), not just wall-clock, when choosing runner SKUs.

## 22.6 Best practices
- **Cache first, parallelize independent jobs, shard tests, cancel stale runs** — in that order of
  ROI.
- **Composite actions/reusable workflows** for shared setup — DRY and consistent.
- **macOS only where required; Linux for the rest.**
- **Archive on merge/tag, not every PR; docs changes skip CI.**
- **Measure → optimize the biggest bar → re-measure.** Don't guess.

---

**Next:** [Part 23 — Security](part-23-security.md).
