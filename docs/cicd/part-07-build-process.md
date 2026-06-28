# Part 7 — The Build Process, command by command

Before we let Fastlane wrap everything (Part 8), you need to understand the raw commands it runs
underneath. If you know what `xcodebuild` actually does, you can debug any CI failure — because
Fastlane is mostly a friendly front-end over these.

## 7.1 The pipeline of commands

```
 resolve deps        build/test            archive               export
 ───────────         ──────────            ───────               ──────
 swift package  ─▶   xcodebuild      ─▶    xcodebuild      ─▶    xcodebuild
 resolve             build / test          archive               -exportArchive
   │                   │                      │                      │
   ▼                   ▼                      ▼                      ▼
 Package.resolved   DerivedData/          App.xcarchive         App.ipa  (signed, uploadable)
 (pinned versions)  .app (simulator)      (Release .app +
                                           dSYMs + bitcode)
```

Two different outputs matter:
- a **`.app`** is what runs in the Simulator / on a dev device (build & test).
- an **`.xcarchive`** is a Release bundle (app + debug symbols) you can **export** into an
  **`.ipa`** for TestFlight/App Store.

## 7.2 `swift package resolve` (dependency resolution)

```bash
xcodebuild -resolvePackageDependencies \
  -project App/App.xcodeproj \
  -scheme ProductionApp-QA
# (or, for a pure SwiftPM package:  swift package resolve)
```

**What it does.** Reads your package requirements (e.g. "Alamofire 5.x"), walks the dependency
graph, picks concrete versions that satisfy everyone, downloads them, and writes the exact chosen
versions to **`Package.resolved`**.

**Why it's its own step.** Resolving + downloading is slow and network-bound. Doing it explicitly
lets CI **cache** the result (Part 13) and fail early with a clear "couldn't resolve dependencies"
rather than burying it inside a build.

**`Package.resolved` is the lockfile** — commit it. It's what makes "the same commit builds the
same dependencies" true, and it's the cache key.

## 7.3 `xcodebuild build` (compile)

```bash
xcodebuild build \
  -project App/App.xcodeproj \
  -scheme ProductionApp-QA \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5" \
  -derivedDataPath DerivedData
```

| Flag | Meaning |
|------|---------|
| `-project` / `-workspace` | the Xcode project (use `-workspace` if you have a `.xcworkspace`) |
| `-scheme` | which scheme — defines targets, build config mapping, and which `.xcconfig` (Part 19) |
| `-configuration` | `Debug` or `Release` build settings |
| `-destination` | where to build/run for — a simulator, device, or "generic/platform=iOS" |
| `-derivedDataPath` | where intermediate build products + caches go (cacheable) |

**Internals.** `xcodebuild` resolves the scheme → targets → build settings (merging the
`.xcconfig`), compiles Swift/ObjC, links, and produces a `.app` in `DerivedData`. Nonzero exit =
compile/link error = CI fails.

## 7.4 `xcodebuild test`

```bash
set -o pipefail
xcodebuild test \
  -project App/App.xcodeproj \
  -scheme ProductionApp-QA \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=17.5" \
  -resultBundlePath TestResults.xcresult \
  | xcbeautify
```

**What it does.** Builds the app + test targets, boots the simulator, runs XCTest unit and/or UI
tests, and writes a structured **`.xcresult`** bundle (pass/fail, logs, coverage, screenshots).

- `-resultBundlePath` → the `.xcresult` you upload as an artifact (Part 14) and parse for coverage
  (Part 11).
- `-only-testing:` / `-skip-testing:` → run a subset (e.g. unit only on PRs, UI on merge).
- `set -o pipefail` → because piping to `xcbeautify` would otherwise mask `xcodebuild`'s exit code
  and hide test failures.

## 7.5 `xcodebuild archive` (the Release build)

```bash
xcodebuild archive \
  -project App/App.xcodeproj \
  -scheme ProductionApp-Production \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/ProductionApp.xcarchive \
  CODE_SIGNING_ALLOWED=YES                    # archive must be signed (Part 9)
```

**What it does.** Produces an **`.xcarchive`** — a Release-configured, **device** build (note
`generic/platform=iOS`, *not* a simulator: TestFlight/App Store need an ARM device binary), bundled
with **dSYMs** (debug symbols for crash symbolication). This is the canonical "build to ship."

**Why separate from export.** One archive can be exported multiple ways (App Store, Ad Hoc,
Enterprise) with different profiles. Archiving = "compile the release binary"; exporting = "package
+ sign it for a specific distribution channel."

## 7.6 `-exportArchive` → the `.ipa`

```bash
xcodebuild -exportArchive \
  -archivePath build/ProductionApp.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

`ExportOptions.plist` tells Xcode *how* to package:
```xml
<dict>
  <key>method</key>           <string>app-store</string>   <!-- or ad-hoc / enterprise -->
  <key>teamID</key>           <string>ABCDE12345</string>
  <key>signingStyle</key>     <string>manual</string>       <!-- CI uses manual + Match (Part 9) -->
  <key>provisioningProfiles</key>
  <dict>
    <key>com.acme.productionapp</key>
    <string>match AppStore com.acme.productionapp</string>
  </dict>
</dict>
```

**What it does.** Takes the archive, **re-signs** the `.app` with the distribution certificate +
the chosen provisioning profile, and wraps it into **`App.ipa`** — the file you upload to App Store
Connect / TestFlight.

```
.xcarchive  ──(sign with Distribution cert + AppStore profile)──▶  App.ipa
```

## 7.7 The whole thing, end to end

```
swift package resolve              # pin + fetch deps        → Package.resolved
       │
xcodebuild test  (Debug, sim)      # prove it works          → TestResults.xcresult
       │
xcodebuild archive (Release, dev)  # build to ship           → ProductionApp.xcarchive (+dSYMs)
       │
xcodebuild -exportArchive          # sign + package          → ProductionApp.ipa
       │
upload to App Store Connect        # (Part 15)               → TestFlight
```

Fastlane (Part 8) names these steps `gym`/`build_app` (archive+export), `scan` (test),
`upload_to_testflight` (upload) — but they shell out to exactly these commands.

## 7.8 Common mistakes
- **Archiving for a simulator** (`-destination` sim) → you get a non-distributable binary. Use
  `generic/platform=iOS`.
- **Piping `xcodebuild` without `set -o pipefail`** → failing tests show a green step.
- **Forgetting `Package.resolved`** in git → non-reproducible deps and cache misses.
- **Mismatched `ExportOptions` method/profile** → "no matching provisioning profile" at export.
- **Not collecting dSYMs** → unsymbolicated crash reports later (Part 16/Crashlytics).

## 7.9 Debugging
- Add `-verbose`, or read the raw log (don't only read `xcbeautify`'s summary).
- `xcodebuild -list -project App/App.xcodeproj` → list schemes/targets/configs (typo in `-scheme`
  is the #1 failure).
- `xcrun simctl list devices available` → validate `-destination`.
- Open the `.xcresult` in Xcode (or `xcrun xcresulttool`) to inspect failures/coverage.
- Reproduce the **exact** CI command locally — same Xcode, same flags.

## 7.10 Best practices
- **Let Fastlane own these commands** (Part 8) so local == CI, but know what they expand to.
- **Resolve deps as a discrete, cached step.**
- **Test in Debug on simulator; archive in Release for generic iOS device.**
- **Keep `ExportOptions.plist` in the repo** and signing **manual** on CI (predictable, with
  Match; Part 9).
- **Always retain `.xcarchive` + dSYMs + `.xcresult`** as artifacts for the shipped build.

---

**Next:** [Part 8 — Fastlane](part-08-fastlane.md): wrap all of this into reusable lanes that
humans and CI call identically.
