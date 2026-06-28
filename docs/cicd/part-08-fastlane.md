# Part 8 — Fastlane, beginner to advanced

Part 7 showed the raw `xcodebuild` commands. Typing those — with all the signing, export, and
upload flags — by hand is error-prone and impossible to keep identical between your laptop and CI.
**Fastlane** is the fix: you define **lanes** (named recipes) once, and everyone runs the same
lane. It's the "thick" layer the thin YAML calls (Part 3).

The real files for this part are committed at [`fastlane/`](../../fastlane/) and
[`Gemfile`](../../Gemfile).

## 8.1 What Fastlane is

A Ruby tool + a library of ~400 **actions** (`scan` = test, `gym` = build/archive,
`match` = signing, `pilot` = TestFlight, `increment_build_number`, `slack`, …). You compose actions
into **lanes** in a `Fastfile`. You run `bundle exec fastlane <lane>`.

```
 bundle exec fastlane beta
        │
        ▼
 Fastfile: lane :beta
   ├─ match(...)                 # signing      → Part 9
   ├─ increment_build_number     # versioning   → Part 20
   ├─ build_app(scheme: ...)     # = gym = xcodebuild archive + -exportArchive (Part 7)
   ├─ upload_to_testflight       # = pilot      → Part 15
   └─ slack(message: ...)        # notify       → Part 17
```

## 8.2 The four config files

### `Gemfile` (repo root) — pin the tooling
```ruby
source "https://rubygems.org"
gem "fastlane"
gem "cocoapods"        # only if you use CocoaPods
plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
```
`bundle install` reads this; `Gemfile.lock` pins exact versions so CI runs the *same* fastlane you
do. Always invoke as **`bundle exec fastlane`** so the pinned version is used.

### `Appfile` — identity
```ruby
app_identifier("com.acme.productionapp")     # your bundle id
apple_id("ci@acme.com")                       # Apple account used for uploads
itc_team_id("123456789")                      # App Store Connect team
team_id("ABCDE12345")                         # Developer Portal team
```
Centralizes the IDs every lane needs so you don't repeat them.

### `Matchfile` — code signing (full story in Part 9)
```ruby
git_url("git@github.com:acme/ios-certificates.git")   # private repo holding encrypted certs
storage_mode("git")
type("development")                                     # default; lanes override per use
app_identifier(["com.acme.productionapp"])
```

### `Pluginfile` — extra actions
```ruby
gem "fastlane-plugin-versioning"        # finer version/build-number control
```

## 8.3 Fastfile concepts

### `lane` — a public recipe
```ruby
lane :test do
  run_tests(scheme: "ProductionApp-QA")
end
```
Run with `fastlane test`. Lanes are the unit everyone calls.

### `private_lane` — internal helper, not directly callable
```ruby
private_lane :sign do |options|
  match(type: options[:type], readonly: is_ci)
end
```
Used to share steps between lanes (DRY) without exposing them as top-level commands.

### `action` — a single built-in step
`run_tests` (alias `scan`), `build_app` (`gym`), `match`, `upload_to_testflight` (`pilot`),
`increment_build_number`, `slack`. Each wraps `xcodebuild`/API calls from Part 7.

### `before_all` / `after_all` / `error` — lifecycle hooks
```ruby
before_all do
  setup_ci                      # creates a temporary keychain on CI (vital for signing)
  xcversion(version: "16.0")    # pin Xcode
end

after_all do |lane|
  slack(message: "✅ #{lane} succeeded") if is_ci
end

error do |lane, exception|
  slack(message: "❌ #{lane} failed: #{exception.message}", success: false) if is_ci
end
```
`before_all` runs before every lane (setup), `after_all` on success, `error` on any exception — so
notifications/cleanup are centralized, not copy-pasted into each lane.

## 8.4 Production lanes (committed `Fastfile`)

The full file is at [`fastlane/Fastfile`](../../fastlane/Fastfile). Highlights:

```ruby
default_platform(:ios)

platform :ios do
  before_all do
    setup_ci if is_ci           # temp keychain + CI-safe settings
  end

  desc "Lint & format check"
  lane :lint do
    swiftlint(strict: true, raise_if_swiftlint_fails: true)   # plugin or shell
    sh("swiftformat --lint ..")
  end

  desc "Run unit + UI tests"
  lane :test do
    run_tests(
      scheme: "ProductionApp-QA",
      devices: ["iPhone 15"],
      result_bundle: true,                # → .xcresult artifact
      code_coverage: true
    )
  end

  desc "Build a Release archive (no upload) — used to validate signing"
  lane :build do
    sync_signing(type: "appstore")        # private_lane wrapping match (below)
    build_app(
      scheme: "ProductionApp-Production",
      configuration: "Release",
      export_method: "app-store"
    )
  end

  desc "Ship a beta to TestFlight"
  lane :beta do
    sync_signing(type: "appstore")
    increment_build_number(build_number: latest_testflight_build_number + 1)
    build_app(scheme: "ProductionApp-Production", export_method: "app-store")
    upload_to_testflight(
      api_key: asc_api_key,               # App Store Connect API key (Part 10)
      skip_waiting_for_build_processing: true
    )
  end

  desc "Release to the App Store (submit for review)"
  lane :release do
    sync_signing(type: "appstore")
    build_app(scheme: "ProductionApp-Production", export_method: "app-store")
    upload_to_app_store(                  # = deliver: metadata + binary (Part 16)
      api_key: asc_api_key,
      submit_for_review: true,
      automatic_release: false,           # human still clicks "Release" in ASC
      force: true                          # skip the HTML preview prompt on CI
    )
  end

  desc "Generate App Store screenshots"
  lane :screenshots do
    capture_screenshots(scheme: "ProductionApp-UITests")
    # frame_screenshots  # optional device frames
  end

  # ---- shared helpers ----
  private_lane :sync_signing do |opts|
    match(type: opts[:type], readonly: is_ci)   # readonly on CI: never create new certs
  end

  def asc_api_key
    app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_P8"],     # base64/PEM from a secret (Part 10)
      is_key_content_base64: true
    )
  end
end
```

### Why this shape
- **`before_all { setup_ci }`** — on CI, signing needs a temporary keychain; `setup_ci` creates it
  and tweaks settings so Match/codesign work headless. Skipped locally.
- **`sync_signing` private lane** — one signing path reused by build/beta/release; `readonly: is_ci`
  guarantees CI never mints new certificates (it only *uses* what Match already stored).
- **`run_tests(result_bundle: true)`** — emits the `.xcresult` your workflow uploads.
- **`upload_to_testflight(skip_waiting...)`** — don't burn runner minutes idling while Apple
  processes the build.
- **`upload_to_app_store(automatic_release: false)`** — automates everything *except* the final
  human go-live (iOS = Continuous Delivery; Part 1).
- **`asc_api_key` helper** — builds the App Store Connect API key object from secrets, in one place.

## 8.5 How CI calls it (ties back to Part 5)
```yaml
# beta.yml step
- run: bundle exec fastlane beta
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
    ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
    ASC_KEY_P8: ${{ secrets.ASC_KEY_P8 }}
```
The YAML is one line of build logic; everything else lives in the lane and runs identically on a
laptop (`bundle exec fastlane beta`).

## 8.6 Common mistakes
- **Running `fastlane` without `bundle exec`** → uses a different global fastlane version than the
  lockfile; "works on my machine."
- **Forgetting `setup_ci`** → signing fails on CI with keychain errors.
- **`match` not `readonly` on CI** → CI may try to *create* certs, hit the 2-cert limit, and break
  every other build.
- **Hardcoding IDs/keys in the Fastfile** → put them in `Appfile`/secrets.
- **Duplicating steps across lanes** → use `private_lane`/helpers.

## 8.7 Debugging
- `fastlane lanes` lists lanes; `fastlane <lane> --verbose` prints every action + the underlying
  `xcodebuild`.
- Fastlane prints the exact `xcodebuild`/`xcrun` command — copy it to reproduce (Part 7).
- `fastlane env` dumps versions/plugins for bug reports.
- Signing issues → `match --verbose`, and check the certificates repo + `MATCH_PASSWORD` (Part 9).

## 8.8 Best practices
- **One lane per CI job's "how."** Workflow names the *when*; lane owns the *how*.
- **`bundle exec` always; commit `Gemfile.lock`.**
- **`readonly` Match on CI; mint certs only from one controlled place** (a human or a dedicated
  job).
- **Centralize notifications in `after_all`/`error`,** not in every lane.
- **Keep lanes runnable locally** — that's the whole point; it kills "works in CI only."

---

**Next:** [Part 9 — Code Signing & Match](part-09-code-signing.md): certificates, profiles, Team
IDs, manual vs automatic signing, and how Match makes it all reproducible on CI.
