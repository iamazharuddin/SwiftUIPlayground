# Part 19 — Environment Management (Dev / QA / Staging / Production)

One codebase must build four different apps: pointing at different API URLs, with different bundle
ids (so they install side-by-side), names, icons, and feature flags. This part shows how schemes +
build configurations + `.xcconfig` files express that cleanly — with real config files committed
under [`Configurations/`](../../Configurations/).

## 19.1 The three concepts and how they relate

```
 Scheme  ──selects──▶  Build Configuration  ──includes──▶  .xcconfig file  ──defines──▶  settings
 (what you            (Debug/Release flavor               (text key=value)              (API_URL,
  pick in Xcode/       per environment)                                                  BUNDLE_ID…)
  -scheme on CI)
```

- **Build Configuration** — Xcode's flavor of build settings. Default is `Debug`/`Release`; we add
  per-environment ones so each env has its own settings + `.xcconfig`.
- **`.xcconfig`** — plain-text build settings (Part 3). One per environment; all inherit a `Base`.
- **Scheme** — the thing you select (`-scheme` on CI). Each scheme maps its actions
  (Run/Test/Archive) to a configuration, so picking a scheme picks an environment.

```
 Schemes                         Configurations          .xcconfig
 ProductionApp-Dev        ──▶    Debug-Dev         ──▶   Dev.xcconfig         (+ Base)
 ProductionApp-QA         ──▶    Debug-QA / Rel-QA ──▶   QA.xcconfig          (+ Base)
 ProductionApp-Staging    ──▶    Release-Staging   ──▶   Staging.xcconfig     (+ Base)
 ProductionApp-Production ──▶    Release           ──▶   Production.xcconfig  (+ Base)
```

## 19.2 What differs per environment

| Setting | Dev | QA | Staging | Production |
|---------|-----|----|---------| ---------- |
| `API_BASE_URL` | dev-api | qa-api | staging-api | api |
| `PRODUCT_BUNDLE_IDENTIFIER` | …app.dev | …app.qa | …app.staging | …app |
| `PRODUCT_NAME` (app name) | App Dev | App QA | App Stg | App |
| App icon | dev (orange) | qa (purple) | stg (blue) | prod |
| Feature flags | all on | most on | release set | release set |
| Logging | verbose | verbose | info | warn |

The **distinct bundle ids** are why a dev can have Dev + QA + Prod installed simultaneously on one
phone — they're different apps to iOS.

## 19.3 The real `.xcconfig` files

### [`Configurations/Base.xcconfig`](../../Configurations/Base.xcconfig) — shared
```
PRODUCT_BUNDLE_IDENTIFIER = com.acme.productionapp$(BUNDLE_ID_SUFFIX)
MARKETING_VERSION = 1.4.0
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 16.0
// API_BASE_URL / BUNDLE_ID_SUFFIX / APP_DISPLAY_NAME are set per-environment below.
```

### [`Configurations/QA.xcconfig`](../../Configurations/QA.xcconfig) — one env
```
#include "Base.xcconfig"
BUNDLE_ID_SUFFIX = .qa
APP_DISPLAY_NAME = App QA
API_BASE_URL = https:/$()/qa-api.acme.com   // $() prevents // being read as a comment
LOG_LEVEL = debug
```

- **`#include "Base.xcconfig"`** → inherit shared settings; override only what differs.
- **`$(BUNDLE_ID_SUFFIX)`** → Base composes the final bundle id from a per-env suffix, so Production
  is `com.acme.productionapp` and QA is `com.acme.productionapp.qa`.
- **`https:/$()/…`** → the classic `.xcconfig` gotcha: `//` starts a comment, so you split it with
  the empty `$()` variable. Otherwise your URL gets truncated to `https:`.

## 19.4 Surfacing values to Swift

`.xcconfig` sets *build settings*; to read them at runtime, pipe them into Info.plist and read via
`Bundle`:

```
// In Info.plist:  <key>API_BASE_URL</key> <string>$(API_BASE_URL)</string>
```
```swift
enum AppEnvironment {
    static var apiBaseURL: URL {
        let s = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as! String
        return URL(string: "https://\(s)")!
    }
}
```
Now `AppEnvironment.apiBaseURL` is whatever the **scheme's** `.xcconfig` set — no `if isQA`
branches in code (Part 3 mistake).

## 19.5 Feature flags

Two layers, complementary:
- **Build-time flags** (in `.xcconfig` → `SWIFT_ACTIVE_COMPILATION_CONDITIONS` or Info.plist) → set
  per environment, compiled in. Good for "this screen only exists in Dev."
- **Runtime/remote flags** (Firebase Remote Config, LaunchDarkly, your own endpoint) → flip without
  a release → the **kill switch** that powers fast rollback (Part 18). Good for "dark-launch this
  feature, enable for 5% of prod."

```swift
if FeatureFlags.newCheckout.isEnabled { NewCheckoutView() } else { LegacyCheckoutView() }
```

## 19.6 How CI selects an environment

It's just the scheme (Parts 4–5):
```yaml
# ci.yml   → QA scheme for PR validation
env: { SCHEME: "ProductionApp-QA" }
# beta.yml → Production scheme for TestFlight
run: bundle exec fastlane beta   # lane uses scheme "ProductionApp-Production"
```
Same source, four apps, selected entirely by `-scheme` → configuration → `.xcconfig`.

## 19.7 Common mistakes
- **`//` in an `.xcconfig` URL** → silently truncated; use `https:/$()/`.
- **Hardcoding env differences in Swift** (`if isStaging`) → put them in `.xcconfig` + Info.plist.
- **Same bundle id across envs** → can't co-install; QA overwrites Prod on a device.
- **Forgetting to map a new config in the scheme** → it builds the wrong env's settings.
- **Secrets in `.xcconfig`** → these are committed; real secrets go in GitHub Secrets (Part 10),
  not here. `.xcconfig` holds *non-secret* config (URLs, flags, ids).

## 19.8 Debugging
- `xcodebuild -showBuildSettings -scheme ProductionApp-QA | grep -E 'BUNDLE_IDENTIFIER|API_BASE'` →
  confirm the resolved values per scheme.
- Wrong API in the build → check which configuration the scheme's Archive/Run action points at.
- `.xcconfig` value not applying → ensure the config file is assigned to the configuration in
  project settings, and the setting isn't overridden in the target's build settings (target
  overrides win over `.xcconfig`).

## 19.9 Best practices
- **One `.xcconfig` per env, all inheriting `Base`; override only differences.**
- **Distinct bundle ids** via a suffix variable → side-by-side installs.
- **Config in `.xcconfig`, secrets in GitHub Secrets** — never mix.
- **No environment `if` ladders in Swift** — read injected values.
- **Remote feature flags for risky features** — decouples release from enablement (Part 18).
- **Select env by scheme** in CI; keep it the only switch.

---

**Next:** [Part 20 — Versioning](part-20-versioning.md).
