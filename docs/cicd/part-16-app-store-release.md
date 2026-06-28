# Part 16 — App Store Release

TestFlight (Part 15) gets builds to testers. This part takes a vetted build all the way to the
public App Store — metadata, submission, review, and the deliberate **human go-live gate** that
makes iOS "Continuous Delivery, not Deployment" (Part 1). Ships the real `release.yml`.

## 16.1 The flow

```
 git tag v1.4.0  (or GitHub Release)
      │
      ▼
 Archive (Release, Production scheme) ─▶ Export .ipa (Distribution + AppStore profile)   (Parts 7,9)
      │
      ▼
 Upload binary  +  Metadata           ─▶ App Store Connect    (deliver / upload_to_app_store)
      │           (name, description,
      │            keywords, screenshots,
      │            release notes, version)
      ▼
 Submit for Review
      │
      ▼
 [ Apple App Review ]   automated + human checks (hours–days)
      │
      ▼
 Approved
      │
      ▼
 [ HUMAN clicks "Release" ]   ← the deliberate gate (or phased rollout)
      │
      ▼
 Live on the App Store
```

## 16.2 The pieces of a release

| Piece | What it is | Where it lives |
|-------|-----------|----------------|
| **Marketing version** | the public version, e.g. `1.4.0` (semver; Part 20) | `CFBundleShortVersionString` |
| **Build number** | unique, increasing per upload, e.g. `412` | `CFBundleVersion` |
| **Metadata** | name, subtitle, description, keywords, support URL | `fastlane/metadata/` (deliver) |
| **Screenshots** | per device size, per locale | `fastlane/screenshots/` (Part 15 `capture_screenshots`) |
| **Release notes** | "What's New in This Version" | `fastlane/metadata/<locale>/release_notes.txt` |
| **Review info** | demo account, contact, notes for the reviewer | deliver config |

`deliver` (the engine behind `upload_to_app_store`) treats this as **metadata-as-code**: the text
files in `fastlane/metadata/` are the source of truth, versioned in git and pushed to ASC.

## 16.3 The `release` lane (recap from Part 8)

```ruby
lane :release do
  sync_signing(type: "appstore")
  build_app(scheme: "ProductionApp-Production", export_method: "app-store")
  upload_to_app_store(
    api_key: asc_api_key,
    submit_for_review: true,        # push it into Apple's review queue
    automatic_release: false,       # DON'T auto-go-live: a human clicks Release
    force: true,                    # skip the interactive HTML metadata preview on CI
    precheck_include_in_app_purchases: false
  )
end
```

- **`submit_for_review: true`** — automates the "Submit" click.
- **`automatic_release: false`** — the key line: after approval the build **waits** for a human in
  ASC to release it (or you set a scheduled/phased release). This is the human gate.
- **`force: true`** — `deliver` normally opens an HTML preview for you to confirm; on CI there's no
  browser, so skip it.

### Phased release (recommended for prod)
```ruby
upload_to_app_store(
  api_key: asc_api_key,
  submit_for_review: true,
  automatic_release: false,
  phased_release: true              # roll out to 1%→2%→…→100% over 7 days; pausable
)
```
Phased release limits blast radius: if crash rates spike, you **pause** the rollout instead of
hot-fixing the whole user base (ties to Part 18 rollback).

## 16.4 The real `release.yml` — gated by an Environment

The release workflow triggers on a **version tag** and runs inside a `production` GitHub
**Environment** that requires **manual approval** before the job (and its secrets) unlock
(Part 10). So even pushing a tag can't ship without a human approving the deploy.

Committed at [`.github/workflows/release.yml`](../../.github/workflows/release.yml):
```yaml
name: Release (App Store)

on:
  push:
    tags: [ "v*" ]            # e.g. git tag v1.4.0 && git push --tags
  workflow_dispatch:
    inputs:
      version: { description: "Marketing version (e.g. 1.4.0)", required: true }

permissions:
  contents: write             # create/update the GitHub Release

jobs:
  release:
    runs-on: macos-14
    environment: production    # ← requires a reviewer to approve before this job runs
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Select Xcode
        run: sudo xcode-select -s "/Applications/Xcode_16.0.app"
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }
      - name: Decode secrets
        run: ./Scripts/decode_secrets.sh
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_KEY_P8: ${{ secrets.ASC_KEY_P8 }}
      - name: Build, upload, submit for review
        run: bundle exec fastlane release
        env:
          MATCH_PASSWORD:                ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
          ASC_KEY_ID:                    ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID:                 ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8:                    ${{ secrets.ASC_KEY_P8 }}
      - name: Attach IPA + dSYMs to the GitHub Release
        if: always()
        uses: softprops/action-gh-release@v2
        with:
          files: |
            build/*.ipa
            **/*.dSYM
      - name: Notify Slack
        if: always()
        run: ./Scripts/notify_slack.sh "${{ job.status }}" "App Store submission ${{ github.ref_name }}"
        env: { SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }} }
```

### Why this shape
- **Tag-triggered** → releases are tied to an immutable, reviewable git tag (`v1.4.0`).
- **`environment: production`** → a required reviewer must approve in the Actions UI before the job
  starts; production secrets live in that environment scope (Part 10). This is the technical
  enforcement of "a human ships."
- **Attach to GitHub Release** → the exact shipped `.ipa` + dSYMs are stored **durably** (not just
  Actions retention; Part 14), the canonical record for that version and the source for rollback
  (Part 18).
- **`automatic_release: false` in the lane** → even after approval + review, going *live* is still
  a click in ASC. Two gates: deploy-approval (GitHub) and go-live (ASC).

## 16.5 Common mistakes
- **Reusing/decreasing the build number** → ASC rejects. Auto-bump (Part 20).
- **`automatic_release: true` by accident** → app goes live the instant Apple approves, maybe at
  3am with no one watching. Keep it false (or phased).
- **Screenshots missing for a required device size/locale** → review rejection. `deliver` validates
  this; run `precheck`.
- **Missing export-compliance key** (`ITSAppUsesNonExemptEncryption`) → manual prompt blocks
  automation.
- **No demo account in review notes** for a login-gated app → reviewer can't test → rejection.

## 16.6 Debugging
- `fastlane deliver --verbose` (or `release --verbose`) → see metadata diff + ASC API responses.
- `fastlane precheck` → catch metadata/screenshot/compliance problems *before* submitting.
- Review rejection → read the Resolution Center message; common: guideline 2.1 (crashes), 4.x
  (design), missing privacy/permission strings.
- Validate the binary pre-upload: `fastlane deliver --verify_only` / `xcrun altool --validate-app`.

## 16.7 Best practices
- **Tag-driven releases** + **Environment approval** + **`automatic_release: false`** = controlled,
  auditable shipping.
- **Metadata-as-code** in `fastlane/metadata/`, reviewed in PRs like any change.
- **Phased release** for production; pause on bad metrics rather than scrambling a hotfix.
- **Store every release `.ipa`+dSYMs on the GitHub Release** for rollback + symbolication.
- **Run `precheck` in CI** before submit to fail fast on metadata issues.

---

**Next:** [Part 17 — Notifications](part-17-notifications.md).
