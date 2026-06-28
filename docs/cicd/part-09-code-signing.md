# Part 9 — Code Signing & Fastlane Match

Code signing is where most iOS CI setups break, because it's the one place Apple's security model
collides with "a fresh, stateless cloud Mac." This part builds the mental model, then shows how
**Match** makes signing reproducible on any machine.

## 9.1 The concepts (and how they relate)

```
 Apple Developer Program  (the paid account, identified by a TEAM ID, e.g. ABCDE12345)
   │
   ├── Certificates ............ prove "this build came from us"
   │     ├── Development cert ... run on registered dev devices
   │     └── Distribution cert .. ship via TestFlight / App Store
   │           (each is a public/PRIVATE key pair; the private key must be on the build machine)
   │
   ├── Identifiers / Bundle IDs . com.acme.productionapp  (one per app/extension)
   │
   ├── Devices ................. UDIDs registered for development/ad-hoc
   │
   └── Provisioning Profiles ... the GLUE: bind { App ID + Certificate + (Devices) + Entitlements }
         ├── Development profile
         ├── Ad Hoc profile      (specific devices)
         └── App Store profile   (TestFlight + App Store)
```

In one sentence: **a provisioning profile says "this Bundle ID, signed by this certificate, with
these entitlements, may run here."** To sign, the build machine needs the **certificate's private
key** (in its Keychain) **and** the matching **profile**.

| Term | Plain meaning |
|------|---------------|
| **Team ID** | your org's id in Apple's portal (`ABCDE12345`) |
| **Bundle Identifier** | the app's unique id (`com.acme.productionapp`) |
| **Development cert** | sign builds for dev devices |
| **Distribution cert** | sign builds for TestFlight/App Store |
| **Provisioning profile** | binds app id + cert + entitlements (+ devices) |
| **Entitlements** | capabilities (push, app groups, iCloud…) baked into the profile |

## 9.2 Automatic vs manual signing

**Automatic ("Xcode managed").** Xcode logs into your Apple account and creates/downloads certs &
profiles for you. Great on a developer laptop; **bad on CI** because:
- it needs interactive Apple auth,
- it can silently *create* certs and hit Apple's **limited cert count**,
- each clean runner would regenerate things → non-reproducible, racy.

**Manual.** You explicitly provide the cert + profile. Predictable and CI-friendly — but managing
them by hand across a team is painful. **Match automates manual signing.**

## 9.3 The CI signing problem

```
 Fresh macOS runner:  empty Keychain, no certs, no profiles.
 To sign it needs:    the Distribution PRIVATE KEY + the App Store profile.
 But:                 you can't commit private keys to the app repo (secret!).
 And:                 the VM is destroyed after the job (Part 6).
```

So we need a way to **securely fetch the same certs/profiles onto any machine on demand**. That's
Match.

## 9.4 How Match works

Match stores your certificates + profiles **encrypted** in a **separate private git repo** (or S3),
and installs them on demand.

```
                 ┌─────────────────────────────────────────────┐
   one-time      │  fastlane match appstore   (run by a human)  │
   (a human):    │   → creates Distribution cert + AppStore     │
                 │     profile in Apple portal                  │
                 │   → ENCRYPTS them with MATCH_PASSWORD        │
                 │   → pushes to  git@github:acme/ios-certs.git │
                 └─────────────────────────────────────────────┘
                                    │
                                    ▼  (encrypted blobs in a private repo)
                 ┌─────────────────────────────────────────────┐
   every CI run  │  fastlane match appstore --readonly          │
   (the runner): │   → clones ios-certs repo                    │
                 │   → DECRYPTS with MATCH_PASSWORD             │
                 │   → installs cert into a temp Keychain        │
                 │   → installs the profile                      │
                 │   → xcodebuild can now sign                   │
                 └─────────────────────────────────────────────┘
```

Key properties:
- **One source of truth** for signing across the whole team + CI. Everyone gets the *same* cert.
- **`--readonly` on CI** → the runner only *consumes* certs; it never creates/revokes (avoids the
  cert-limit footgun and races).
- **Encrypted at rest**; the only secret on the runner is `MATCH_PASSWORD` (+ repo read access),
  injected via GitHub Secrets (Part 10).

## 9.5 The config (committed)

[`fastlane/Matchfile`](../../fastlane/Matchfile):
```ruby
git_url("git@github.com:acme/ios-certificates.git")   # the SEPARATE private certs repo
storage_mode("git")
type("appstore")                                       # default type
app_identifier(["com.acme.productionapp"])
readonly(true)                                         # safe default; humans flip it to create
```

In the Fastfile (Part 8) the `sync_signing` private lane calls:
```ruby
match(type: "appstore", readonly: is_ci)   # readonly only on CI
```

And `build_app` exports with the Match-provided profile (Part 7's `ExportOptions`):
```ruby
build_app(
  scheme: "ProductionApp-Production",
  export_method: "app-store",
  export_options: {
    provisioningProfiles: {
      "com.acme.productionapp" => "match AppStore com.acme.productionapp"
    }
  }
)
```

## 9.6 The end-to-end signing flow on CI

```
beta.yml: bundle exec fastlane beta
   │
   ├─ setup_ci                         # create temp keychain (before_all)
   ├─ match(appstore, readonly)        # clone certs repo, decrypt, install cert+profile
   │     needs: MATCH_PASSWORD, repo read (MATCH_GIT_BASIC_AUTHORIZATION)   ← secrets (Part 10)
   ├─ build_app(export app-store)      # xcodebuild archive + -exportArchive, signed
   └─ upload_to_testflight             # signed .ipa → App Store Connect
```

## 9.7 Secrets this needs (forward ref to Part 10)
- `MATCH_PASSWORD` — decrypts the certs repo.
- `MATCH_GIT_BASIC_AUTHORIZATION` (or an SSH deploy key) — read access to the certs repo.
- App Store Connect **API key** (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`) — to upload without a
  human Apple login.

## 9.8 Common mistakes
- **Automatic signing on CI** → interactive auth + cert sprawl. Use manual + Match.
- **Match not `readonly` on CI** → runner creates certs, hits Apple's limit, breaks everyone.
- **Committing the certs repo to the *app* repo** → private keys leaked. Always a *separate
  private* repo.
- **Missing `setup_ci`** → "errSecInternalComponent"/keychain errors; codesign can't access keys.
- **Profile/cert/Bundle ID mismatch** → "no profile matching" at export. The trio must align.
- **Expired cert/profile** → builds suddenly fail; certs expire (~1 year) — rotate (Part 23).

## 9.9 Debugging
- `fastlane match appstore --readonly --verbose` → see clone/decrypt/install.
- `security find-identity -v -p codesigning` → list certs in the keychain on the runner.
- `xcrun security cms -D -i <profile>.mobileprovision` → inspect a profile's app id/cert/expiry.
- Verify `MATCH_PASSWORD` is set and the certs-repo auth works (`git clone` it in a step).
- Confirm Bundle ID in the project == Matchfile == profile.

## 9.10 Best practices
- **Match + a dedicated private certs repo**, encrypted, `readonly` on CI.
- **One distribution cert per team**, shared via Match — not one-per-developer.
- **App Store Connect API key, not Apple-ID-password**, for uploads (no 2FA prompts, revocable,
  scoped).
- **Rotate certs/keys on a schedule and on offboarding** (Part 23); store only `MATCH_PASSWORD` +
  repo access on runners.
- **Keep signing in a `private_lane`** so build/beta/release share one audited path.

---

**Next (Batch 4):** [Part 10 — Secrets Management](part-10-secrets.md): how those
`MATCH_PASSWORD` / ASC-key / Slack values are stored, scoped, masked, and injected safely.
