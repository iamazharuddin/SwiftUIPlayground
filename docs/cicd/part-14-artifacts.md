# Part 14 — Artifacts

Caching (Part 13) is about **speed** — reusing inputs. **Artifacts** are about **outputs** — the
files a run *produces* that you want to keep: the `.ipa` you shipped, the `.xcresult` of a failed
test, build logs. Because the runner VM is destroyed (Part 6), artifacts are how outputs survive
the job and how files move *between* jobs.

## 14.1 Cache vs Artifact — don't confuse them

| | Cache | Artifact |
|---|-------|----------|
| Purpose | speed up future runs | preserve this run's outputs |
| Content | inputs (deps, build intermediates) | outputs (ipa, results, logs) |
| Keyed by | lockfile hash | a name you choose |
| Lifetime | evicted by LRU/budget | retained N days (you set) |
| Typical use | SPM, gems | `.ipa`, `.xcresult`, coverage, dSYMs |

## 14.2 What to keep, and why

```
 Artifact        Why you keep it
 ────────        ───────────────
 IPA             the EXACT signed binary that shipped → re-upload/rollback (Part 18), audit
 XCArchive       Release build + structure; can re-export or re-sign later
 dSYMs           symbolicate crash reports for THIS build (Crashlytics/ASC)
 .xcresult       inspect test failures/coverage/UI screenshots after the fact (Part 11)
 Logs            raw xcodebuild/fastlane output for debugging a red build
 Coverage report share % on the PR; trend over time
```
Principle: **every shipped build should be reproducible/inspectable from its artifacts** — given a
TestFlight build number, you can find its exact `.ipa`, dSYMs, and test results.

## 14.3 Uploading (real usage)

```yaml
- name: Upload test results
  if: always()                       # keep results even when the job FAILED (that's when you need them)
  uses: actions/upload-artifact@v4
  with:
    name: unit-test-results          # how it appears in the run's Artifacts list
    path: TestResults.xcresult
    retention-days: 14               # auto-delete after 14 days
    if-no-files-found: warn          # don't fail the job if the path is empty
```

Ship-build example (in `beta.yml`):
```yaml
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: beta-build-${{ github.run_number }}
    path: |
      build/*.ipa
      build/*.xcarchive
      **/*.dSYM
    retention-days: 90               # keep shippable artifacts longer
```

**`if: always()` is the key habit** — by default a step is skipped once a previous step failed, but
a *failed* run is exactly when you want the logs/`.xcresult`. `always()` forces the upload.

## 14.4 Passing files between jobs

Artifacts are also the bridge across the fresh-VM boundary: job A uploads, job B downloads.
```yaml
jobs:
  archive:
    runs-on: macos-14
    steps:
      - run: bundle exec fastlane build       # produces build/App.ipa
      - uses: actions/upload-artifact@v4
        with: { name: app-ipa, path: build/App.ipa }
  upload:
    needs: archive
    runs-on: macos-14
    steps:
      - uses: actions/download-artifact@v4
        with: { name: app-ipa, path: build }
      - run: bundle exec fastlane upload_only  # consumes build/App.ipa
```
(For iOS we often do archive+upload in **one** job to avoid re-provisioning a Mac, but this pattern
matters when a cheap Linux job needs a file the macOS job produced.)

## 14.5 Retention

- **Default retention** is repo/org-configurable (commonly 90 days, max 90 for artifacts).
- Set **per-artifact `retention-days`**: short for noisy logs (7–14d), long for shippable binaries
  (90d).
- Artifacts **count against storage quota** and cost money — don't keep giant artifacts forever.
  For permanent keeps (e.g. every release `.ipa`), push to **durable storage** (S3/GCS) or attach
  to a **GitHub Release** (Part 16) instead of relying on Actions retention.

## 14.6 Diagram
```
 build/test job
   ├─ TestResults.xcresult ─▶ upload-artifact "unit-test-results" (14d)
   ├─ build/App.ipa        ─▶ upload-artifact "beta-build-123"    (90d)
   ├─ *.dSYM               ─▶ (same)                              → crash symbolication
   └─ logs                 ─▶ upload-artifact "logs" if always()  (7d)
                                   │
                            Actions UI → download, or download-artifact in a later job
```

## 14.7 Common mistakes
- **No `if: always()`** → the artifact you most need (failed run's logs/`.xcresult`) never uploads.
- **Uploading entire `DerivedData`** → gigabytes, slow, quota-busting. Upload only the specific
  outputs.
- **Relying on Actions retention for permanent release archives** → they expire. Use Releases/S3.
- **Forgetting dSYMs** → crashes from that build can't be symbolicated later.
- **Wrong path globs** → empty artifact; set `if-no-files-found: warn`/`error` deliberately.

## 14.8 Debugging
- Open the run → **Artifacts** section → download and inspect locally (open `.xcresult` in Xcode).
- Empty artifact → the `path:` glob didn't match; print `ls -R build` before upload.
- Between-job transfer failing → names must match exactly between upload and download; check
  `needs:`.

## 14.9 Best practices
- **`if: always()` on results/logs**, scoped paths, sensible `retention-days` per type.
- **Tie artifacts to `github.run_number`/commit** in the name for traceability.
- **Keep shippable `.ipa` + dSYMs** (longer retention or durable storage); short-lived logs.
- **One artifact = one purpose**, named clearly.
- **For permanent release storage**, attach to a GitHub Release or push to S3 — not Actions
  retention.

---

**Next:** [Part 15 — TestFlight Deployment](part-15-testflight.md): the full archive → export →
upload → processing → internal/external testing flow, and the real `beta.yml`.
