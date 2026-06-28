# Part 6 — GitHub-Hosted Runners (and why iOS forces your hand)

A **runner** is the machine that executes a job. iOS CI has one non-negotiable constraint that
shapes everything: **you must build on macOS.** This part explains why, what a hosted macOS runner
gives you, its lifecycle and limits, and the billing math that drives pipeline design.

## 6.1 Runner types

```
                       ┌─────────────────────────────────────────────┐
 GitHub-hosted runners │ GitHub provisions a fresh VM per job         │
                       │  • ubuntu-latest   (Linux — cheapest)        │
                       │  • windows-latest                            │
                       │  • macos-14 / macos-15  (Xcode preinstalled) │ ◀── iOS uses these
                       └─────────────────────────────────────────────┘
                       ┌─────────────────────────────────────────────┐
 Self-hosted runners   │ YOUR Mac hardware, registered to the repo/org│
                       │  • Mac mini rack / MacStadium / on-prem      │
                       │  • you manage Xcode, security, scaling       │
                       └─────────────────────────────────────────────┘
```

- **GitHub-hosted (shared) macOS runner** — GitHub's pool. Zero maintenance, clean each time, but
  metered per-minute and macOS minutes are expensive.
- **Self-hosted runner** — your own Mac(s). Cheaper at scale, faster (warm caches, no per-min
  charge), but **you** patch Xcode, rotate secrets on the box, and harden it. Big orgs (Part 24)
  run fleets of self-hosted Macs.

## 6.2 Why macOS is required

Building, testing, and signing an iOS app depends on Apple-only tooling that **does not exist on
Linux/Windows**:

| Need | Tool | Why macOS-only |
|------|------|----------------|
| Compile/build | `xcodebuild`, Xcode toolchain | Apple ships Xcode for macOS only |
| Run tests | iOS **Simulator** | the Simulator is a macOS app |
| Code sign | `codesign`, Keychain | Apple security stack |
| Archive/export | `xcodebuild archive/-exportArchive` | part of Xcode |

So `runs-on: macos-14` isn't a preference — it's the only option for the build/test/archive jobs.
(You *can* offload non-Xcode work — e.g. a JSON lint or a Slack ping — to cheaper `ubuntu-latest`
jobs to save money; Part 22.)

## 6.3 What a hosted macOS runner provides

Each `macos-14` VM boots from a GitHub-maintained **image** that already contains:
- One or more **Xcode versions** under `/Applications/Xcode_*.app`
- Command-line tools, **Homebrew**, Ruby, Python, Node, `git`
- Preinstalled **simulator runtimes** for common iOS versions

### Selecting Xcode (don't trust the default)
The image ships several Xcodes and a default that **changes over time**. Pin it explicitly:
```bash
sudo xcode-select -s "/Applications/Xcode_16.0.app"
xcodebuild -version            # verify in logs
```
*Why:* a silent default bump (e.g. Xcode 16.0 → 16.1) can change Swift versions or deprecate APIs
and "break a build nobody touched." Pinning makes it reproducible.

### How the simulator works
`xcodebuild ... -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5"` tells Xcode to boot
that simulator runtime and run tests inside it. If the named device/OS isn't on the image, the
build fails with "Unable to find a destination."
```bash
xcrun simctl list devices available     # debug: what's actually installed on this runner
```
Pick devices/OS combos you've confirmed exist on the image, or create them with `xcrun simctl
create`.

## 6.4 The clean-VM lifecycle (and its consequences)

```
job starts ─▶ fresh VM provisioned from image ─▶ runner agent runs your steps
           ─▶ job ends ─▶ VM destroyed ─▶ NOTHING persists
```

Consequences you must design around:
- **No state between jobs.** Each job is a clean slate. To share files between jobs use
  **artifacts** (Part 14); to avoid re-downloading dependencies use **cache** (Part 13).
- **No leftover secrets.** Good for security — keychains, certs, and keys vanish with the VM.
- **First run is "cold."** No warm DerivedData; first build of the day is slowest. Caching narrows
  the gap but can't fully close it on hosted runners (self-hosted keeps caches warm).

## 6.5 How caching helps (preview of Part 13)

Because the VM is wiped, the expensive, repeatable work — fetching Swift packages, building
dependencies — would repeat every run. Caching stores those between runs keyed by a hash of
`Package.resolved`:
```
run #1: resolve+build deps (slow) ─▶ save cache
run #2: restore cache (fast) ─────▶ skip re-downloading
run #3: Package.resolved changed ─▶ cache miss ─▶ rebuild ─▶ save new cache
```

## 6.6 Limits & billing (this drives your design)

- **macOS minutes cost multiples of Linux minutes** (commonly ~10×). A 25-min archive on macOS is
  real money.
- **Concurrency caps** limit how many macOS jobs run at once per plan; excess jobs queue.
- **Job time caps** — set `timeout-minutes` yourself; the default 6h is a budget hazard.

Design implications (why earlier parts made the choices they did):
- `concurrency: cancel-in-progress` — don't pay for stale builds.
- `paths-ignore` for docs — don't boot a Mac for a README.
- **lint/format on cheap runners?** Pure SwiftLint can run on macOS (needs the binary) — but
  non-Xcode steps (JSON checks, Slack) can move to `ubuntu-latest`.
- **Archive only on merge/tag**, not every PR.
- At scale, **self-hosted Macs** flip the economics (fixed hardware cost, warm caches) — the
  tradeoff is ops burden and security hardening.

## 6.7 Common mistakes
- **Not pinning Xcode** → mystery breakage when GitHub bumps the image default.
- **Targeting a simulator that isn't on the image** → "Unable to find a destination." List first.
- **Expecting caches/keychains to persist** across jobs → they don't; use cache/artifacts.
- **Leaving the 6h default timeout** → one hung simulator = a giant bill.
- **Running everything on macOS** → paying macOS rates for work Linux could do.

## 6.8 Debugging
- `xcodebuild -version` and `xcode-select -p` early in the job → confirm the toolchain.
- `xcrun simctl list devices available` → confirm the destination exists.
- `sw_vers` / `system_profiler SPHardwareDataType` → confirm the runner OS/specs.
- Reproduce locally with the **same Xcode** and the **same `xcodebuild` command** the lane runs
  (this is why Fastlane-as-source-of-truth matters).
- For self-hosted: check the runner agent logs and that the box's Xcode/license is accepted
  (`sudo xcodebuild -license accept`).

## 6.9 Best practices
- **Pin Xcode** and, ideally, the runner image label (`macos-14`, not `macos-latest`) for
  reproducibility.
- **Right-size runners:** macOS only where Xcode is needed; Linux for the rest.
- **Always set `timeout-minutes`** and **`concurrency`**.
- **Cache aggressively** (Part 13); on hosted runners accept a cold-ish first run.
- **Consider self-hosted Macs** once macOS-minute spend or build latency hurts — but treat those
  boxes as production infra (patching, least-privilege, secret rotation; Part 23).

---

**Next:** [Part 7 — The Build Process](part-07-build-process.md): exactly what `swift package
resolve`, `xcodebuild`, `archive`, `-exportArchive`, and IPA generation each do, command by
command.
