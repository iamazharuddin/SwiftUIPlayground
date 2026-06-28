# Part 20 — Versioning

iOS has **two** numbers and they do different jobs. Getting them right (and automated) is what
keeps "build 412" traceable to an exact commit and keeps App Store Connect happy. Real helper:
[`Scripts/set_build_number.sh`](../../Scripts/set_build_number.sh).

## 20.1 The two numbers

```
 Marketing version  CFBundleShortVersionString   "1.4.0"   ← what USERS see; semver; you choose
 Build number       CFBundleVersion              "412"     ← internal; unique+increasing per upload
```

| | Marketing version | Build number |
|---|---|---|
| Audience | users, App Store listing | Apple/TestFlight internally |
| Format | semver `MAJOR.MINOR.PATCH` | integer (or `1.4.0.412`) |
| Changes | per release you decide | **every** upload, automatically |
| Uniqueness | can repeat across builds of same version | must be unique & increasing per version train |

ASC rejects an upload whose `(version, build)` it has already seen, and rejects a build number that
isn't higher than the last for that version. So the build number **must** auto-increment.

## 20.2 Semantic versioning (the marketing version)

```
 MAJOR . MINOR . PATCH
   │       │       └─ backward-compatible bug fixes        1.4.0 → 1.4.1
   │       └───────── backward-compatible new features     1.4.1 → 1.5.0
   └───────────────── breaking changes / big releases      1.5.0 → 2.0.0
```
You bump this deliberately, per release — usually by editing `MARKETING_VERSION` in
`Base.xcconfig` (Part 19) or via the release tag.

## 20.3 Build number strategies

Pick one and automate it:

| Strategy | How | Pros / cons |
|----------|-----|-------------|
| **From ASC** | `latest_testflight_build_number + 1` (our Fastfile) | always valid, no local state; needs an API call |
| **Git commit count** | `git rev-list --count HEAD` | deterministic, offline, monotonic; resets if history rewritten |
| **CI run number** | `${{ github.run_number }}` | simple, monotonic per repo; not tied to commits |
| **Timestamp** | `YYYYMMDDHHMM` | unique; large numbers, less meaningful |

Our `beta` lane uses **ASC + 1** (safest against rejection). The committed script demonstrates the
**git commit count** strategy (great when you want a number derivable from the checkout alone).

## 20.4 The real helper

[`Scripts/set_build_number.sh`](../../Scripts/set_build_number.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail
BUILD_NUMBER="$(git rev-list --count HEAD)"     # monotonic, deterministic from history
agvtool new-version -all "$BUILD_NUMBER" >/dev/null   # writes CFBundleVersion to all targets
echo "Set build number to $BUILD_NUMBER"
echo "build_number=$BUILD_NUMBER" >> "${GITHUB_OUTPUT:-/dev/null}"   # expose to later steps (Part 4)
```
- **`git rev-list --count HEAD`** → number of commits → strictly increasing as history grows.
- **`agvtool new-version -all`** → Apple's tool that writes `CFBundleVersion` across targets.
- **`>> $GITHUB_OUTPUT`** → publishes the value so downstream jobs/steps can read it
  (`needs.<job>.outputs.build_number`, Part 4).
- Needs **`fetch-depth: 0`** in checkout (Parts 15–16) so the full history is present to count.

## 20.5 Git tags — tying versions to commits

```
 release 1.4.0 ─▶ git tag v1.4.0 <commit> ─▶ push tag ─▶ triggers release.yml (Part 16)
```
- An **annotated tag** (`git tag -a v1.4.0 -m "…"`) is an immutable, signed-able pointer to the
  exact shipped commit → the anchor for hotfixes (Part 18) and audits.
- Convention: tag = `v` + marketing version. The release workflow keys off `tags: [ "v*" ]`.
- Fastlane can automate it: `add_git_tag(tag: "v#{get_version_number}")` + `push_git_tags`.

## 20.6 Putting it together (automatic flow)
```
 PR merged to develop
   → beta lane: build_number = latest_testflight + 1   → upload (build 412, version 1.4.0)
 Ready to ship 1.4.0
   → bump MARKETING_VERSION if needed, git tag v1.4.0, push
   → release.yml (gated) → App Store
 Next dev cycle
   → bump MARKETING_VERSION to 1.5.0 in Base.xcconfig
```

## 20.7 Common mistakes
- **Manually editing build numbers** → duplicates/regressions → ASC rejections. Automate.
- **Committing the bumped build number back to the repo** → noisy commits + merge conflicts; prefer
  computing it at build time (ASC/commit count) over storing it.
- **`git rev-list --count` with a shallow clone** → wrong/low number. Use `fetch-depth: 0`.
- **Marketing version not bumped between releases** → confusing "1.4.0" with different features.
- **No tag per release** → can't reproduce/branch the exact shipped commit (Part 18).

## 20.8 Debugging
- `agvtool what-version` / `agvtool what-marketing-version` → see current values.
- ASC "build already exists" → your build number didn't increase; check the strategy and history
  depth.
- Mismatch between Info.plist and `.xcconfig` → target build settings override `.xcconfig`
  (Part 19); reconcile.

## 20.9 Best practices
- **Marketing version = deliberate semver in `Base.xcconfig`; build number = automated &
  monotonic.**
- **Prefer derive-at-build (ASC+1 or commit count)** over committing numbers back.
- **Annotated `v<version>` tag per release**, driving `release.yml`.
- **`fetch-depth: 0`** wherever you compute from history.
- **Expose the build number as a step output** so artifacts/notifications can reference it.

---

**Next:** [Part 21 — Pull Request Automation](part-21-pr-automation.md).
