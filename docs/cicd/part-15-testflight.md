# Part 15 — TestFlight Deployment

This is where **CD** becomes real: a merged, signed build lands in testers' hands automatically.
TestFlight is Apple's beta-distribution service inside App Store Connect (ASC). This part walks the
full flow and ships the real `beta.yml`.

## 15.1 The flow

```
 merge to develop
      │
      ▼
 Archive            xcodebuild archive (Release, generic iOS)        → .xcarchive  (Part 7)
      │
      ▼
 Export IPA         -exportArchive (sign w/ Distribution + AppStore profile, Match)  → .ipa  (Part 9)
      │
      ▼
 Upload             upload_to_testflight → App Store Connect API     (auth: ASC API key, Part 10)
      │
      ▼
 Processing         Apple processes the build (minutes–tens of minutes): re-sign checks,
      │             bitcode/symbol processing, validation
      ▼
 Internal Testing   up to 100 internal testers (your team) get it immediately, NO review
      │
      ▼
 External Testing   public/external testers — requires a light Beta App Review (first build)
      │
      ▼
 (promote)          a good beta build can later be submitted to the App Store (Part 16)
```

Key facts:
- **Internal testers** (members of your ASC team) get builds **without review** — instant beta.
- **External testers** (anyone via a public link/group) require a one-time **Beta App Review** per
  build train (lighter/faster than full App Store review).
- The **build number must be unique and increasing** for each upload (Part 20) — Apple rejects
  duplicates.

## 15.2 How Fastlane automates it

Our `beta` lane (Part 8) does archive → export → upload in one call:
```ruby
lane :beta do
  sync_signing(type: "appstore")                                  # Match installs cert+profile
  increment_build_number(build_number: latest_testflight_build_number(api_key: asc_api_key) + 1)
  build_app(scheme: "ProductionApp-Production", export_method: "app-store")   # archive + export .ipa
  upload_to_testflight(api_key: asc_api_key, skip_waiting_for_build_processing: true)
end
```
- **`latest_testflight_build_number + 1`** — asks ASC for the highest build it's seen and bumps,
  guaranteeing uniqueness without manual tracking.
- **`upload_to_testflight`** (alias `pilot`) — uploads the `.ipa` via the ASC API. Can also manage
  tester groups, changelogs, and external submission.
- **`skip_waiting_for_build_processing: true`** — return immediately instead of paying runner
  minutes to watch Apple's processing queue. (Set it false only if a later step needs the processed
  build, e.g. auto-submitting external testing.)

### Distributing to testers + changelog
```ruby
upload_to_testflight(
  api_key: asc_api_key,
  distribute_external: true,
  groups: ["QA", "Beta Users"],
  changelog: ENV["BETA_CHANGELOG"] || last_git_commit[:message],
  skip_waiting_for_build_processing: false   # must wait if distributing externally
)
```

## 15.3 The real `beta.yml`

Committed at [`.github/workflows/beta.yml`](../../.github/workflows/beta.yml):
```yaml
name: Beta (TestFlight)

on:
  push:
    branches: [ "develop" ]        # every merge to develop ships a beta
  workflow_dispatch:                # ...or run manually

concurrency:
  group: beta-${{ github.ref }}
  cancel-in-progress: true          # only the latest merge needs shipping

permissions:
  contents: read

env:
  XCODE_VERSION: "16.0"

jobs:
  beta:
    runs-on: macos-14
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }    # full history → build-number/versioning (Part 20)

      - name: Select Xcode
        run: sudo xcode-select -s "/Applications/Xcode_${XCODE_VERSION}.app"

      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }

      - name: Decode secrets
        run: ./Scripts/decode_secrets.sh
        env:
          ASC_KEY_ID:  ${{ secrets.ASC_KEY_ID }}
          ASC_KEY_P8:  ${{ secrets.ASC_KEY_P8 }}

      - name: Build & upload to TestFlight
        run: bundle exec fastlane beta
        env:
          MATCH_PASSWORD:                ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
          ASC_KEY_ID:                    ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID:                 ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8:                    ${{ secrets.ASC_KEY_P8 }}

      - name: Upload build artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: beta-${{ github.run_number }}
          path: |
            build/*.ipa
            **/*.dSYM
          retention-days: 90

      - name: Notify Slack
        if: always()
        run: ./Scripts/notify_slack.sh "${{ job.status }}" "TestFlight beta"
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

### Line-by-line of the new bits
- **`on: push develop` + `workflow_dispatch`** — auto on merge, plus a manual button.
- **`fetch-depth: 0`** — versioning by commit count needs full history (Part 20).
- **Decode secrets step** — materializes the `.p8` before Fastlane runs (Part 10).
- **`fastlane beta` env block** — exactly the Match + ASC secrets the lane reads.
- **artifact upload `if: always()`** — keep the `.ipa`+dSYMs for rollback/symbolication (Part 14),
  even on failure.
- **Slack `if: always()`** — report success *and* failure (Part 17).

## 15.4 Common mistakes
- **Duplicate/lower build number** → ASC rejects the upload. Always `latest_testflight_build_number + 1`.
- **`distribute_external: true` with `skip_waiting_for_build_processing: true`** → you can't
  distribute a build that isn't processed yet; must wait.
- **Apple-ID + password auth** → 2FA breaks headless upload. Use the ASC **API key** (Part 10).
- **Wrong export method/profile** → "no suitable application records"/signing errors at upload.
- **No dSYM retention** → TestFlight crash reports you can't symbolicate later.

## 15.5 Debugging
- `fastlane beta --verbose` → see archive/export/upload commands + ASC API responses.
- Upload rejected → read the ASC error; common: duplicate build number, missing
  export-compliance/encryption key in Info.plist, invalid provisioning.
- "Stuck processing" on Apple's side is normal (minutes); don't treat it as a CI failure — that's
  why we `skip_waiting...`.
- Verify the ASC API key works: a tiny lane calling `latest_testflight_build_number` proves
  auth.

## 15.6 Best practices
- **Auto-bump build number from ASC**; keep marketing version separate (Part 20).
- **ASC API key auth**, base64 `.p8` secret, `readonly` Match (Parts 9–10).
- **Don't wait on processing** unless a later step needs it — save runner minutes.
- **Internal testers for every develop merge; external (reviewed) for release candidates.**
- **Retain `.ipa` + dSYMs** per build for rollback (Part 18) and crash symbolication.
- **Set export-compliance** (`ITSAppUsesNonExemptEncryption`) in Info.plist to avoid the manual
  encryption prompt blocking automation.

---

**Next (Batch 6):** [Part 16 — App Store Release](part-16-app-store-release.md): metadata,
versioning, submission, review, and the human go-live gate — plus `release.yml`.
