# Part 24 — The Real Enterprise Workflow

This part assembles everything (Parts 1–23) into the day-to-day system a large iOS team actually
runs — from a developer starting a feature to a version live on the App Store, including betas,
staging, and hotfixes. Then a high-level look at how big orgs scale it.

## 24.1 Branching strategy

```
 main ───────●────────────────●────────────────●────────▶   (always shippable; tagged releases)
              \              /  \              /
 develop ──●───●──●──●──●───●────●──●──●──●───●──────────▶   (integration; every merge → TestFlight)
            \         /        \        /
 feature/*   ●───●───●          ●──●──●                      (a dev's work; PR into develop)
 bugfix/*    (same as feature, for defects)
 release/1.5 ────────────────────────●──●─────▶ tag v1.5.0   (stabilize a version; → main)
 hotfix/1.4.1 ──────────────────────────────●─▶ tag v1.4.1   (off a release tag; → main + develop)
```

| Branch | From | Into | Purpose |
|--------|------|------|---------|
| `feature/*` | develop | develop (PR) | new work |
| `bugfix/*` | develop | develop (PR) | non-urgent fixes |
| `release/x.y` | develop | main + develop | stabilize a version (only fixes) |
| `hotfix/x.y.z` | main / tag | main + develop | urgent production fix (Part 18) |
| `main` | — | — | always shippable; each release tagged |
| `develop` | — | — | integration; auto-ships betas |

## 24.2 The end-to-end flow (every stage maps to a Part)

```
 ① Feature dev
    git checkout -b feature/login develop
    push → ci.yml: lint ∥ build+unit-test → Danger          (Parts 4,5,11,12)
    open PR → develop
       ├─ required checks must pass                          (Part 21)
       ├─ CODEOWNERS auto-requests reviewers                 (Part 21)
       └─ Danger enforces tests/size/changelog               (Part 12)
    approved + green → merge (auto-merge optional)

 ② Integration / Beta
    merge to develop → beta.yml                              (Parts 5,15)
       archive(Release) → Match sign → export .ipa           (Parts 7,9)
       build number = ASC+1                                  (Part 20)
       upload → TestFlight (internal testers, no review)     (Part 15)
       Slack: "✅ beta 412"                                  (Part 17)

 ③ Release candidate
    git checkout -b release/1.5 develop                      (stabilize: only fixes)
    QA on Staging scheme / external TestFlight (Beta review) (Parts 15,19)
    merge release/1.5 → main

 ④ Production release
    git tag v1.5.0 && push → release.yml                     (Part 16)
       environment: production → HUMAN approves              (Parts 10,16,23)
       build → submit for review (automatic_release: false)
       phased_release: true                                  (Parts 16,18)
       attach .ipa+dSYMs to GitHub Release                   (Parts 14,18)
    Apple review → HUMAN clicks Release → live (phased)

 ⑤ Hotfix (if prod breaks)
    pause phased release / flip feature flag                 (Part 18)
    git checkout -b hotfix/1.5.1 v1.5.0 → fix → tag v1.5.1
    release.yml (expedited) → live
    merge hotfix back into develop                           (Part 18)
```

## 24.3 The environments map

```
 feature push / PR  → QA scheme        → unit/UI tests          (validate)
 develop merge      → Production scheme → TestFlight internal    (dogfood)
 release/* branch   → Staging scheme    → QA + external beta     (acceptance)
 tag v*             → Production scheme  → App Store (gated)      (ship)
```
(Schemes/`.xcconfig` from Part 19; workflows from Parts 5/15/16.)

## 24.4 Versioning & traceability (Part 20)
- Marketing version bumped deliberately per release in `Base.xcconfig`.
- Build number auto from ASC (or commit count) — always unique/increasing.
- Each release = an annotated `v*` tag → an immutable anchor; the GitHub Release stores the exact
  `.ipa`+dSYMs → reproducible hotfix + crash symbolication.

## 24.5 How the big orgs scale this (high-level)

The *shape* above is industry-standard; at Google/Microsoft/Airbnb/Spotify/Uber scale the deltas
are about **volume, speed, and isolation**, not different concepts:

- **Self-hosted macOS fleets** (hundreds–thousands of Macs; MacStadium/on-prem/orchestrated) — hosted
  runners don't scale to that volume/cost, and warm caches make incremental builds fast (Parts 6,
  13, 22).
- **Faster build systems** — many migrate from raw `xcodebuild` to **Bazel** (or heavy module
  caching) for hermetic, cacheable, distributed builds; remote build caches share artifacts across
  the org.
- **Merge queues / trains** — instead of "merge when green," a **merge queue** tests each PR against
  the *latest* main in sequence so main never breaks even at high merge volume (an industrial
  version of "require branch up to date," Part 21).
- **Trunk-based + feature flags** — many large teams use short-lived branches off a single trunk and
  ship *dark* behind flags, decoupling deploy from release entirely (Parts 18, 19).
- **Release trains** — fixed cadence (e.g. weekly); whatever's merged and flag-ready rides the next
  train; a release-engineering team owns the tag→submit→go-live process.
- **Dedicated DevOps/Developer-Experience teams** own the runners, signing, caches, and pipeline
  reliability as a product for the app teams.
- **Heavy observability** — build-time dashboards, flaky-test quarantine systems, crash/ANR
  pipelines wired to dSYMs, cost monitoring per team.

The throughline: **same primitives** (CI gate, signed CD, environments, versioning, rollback,
security) — scaled with better hardware, faster build tooling, merge queues, and a team that owns
the pipeline itself.

## 24.6 Putting it on this repo (recap of what's committed)
```
.github/workflows/  ci.yml · beta.yml · release.yml
.github/actions/    setup-ios/ (composite)
.github/            CODEOWNERS
fastlane/           Fastfile · Appfile · Matchfile · Pluginfile
Configurations/     Base/Dev/QA/Staging/Production .xcconfig
Scripts/            decode_secrets.sh · notify_slack.sh · set_build_number.sh
Gemfile · Dangerfile · .swiftlint.yml · .swiftformat
docs/cicd/          Parts 1–24 (this masterclass)
```
These are production-shaped references for the hypothetical app; wire the project/scheme/secrets
(Parts 10, 19) to make them run against a real target.

## 24.7 Best practices (the whole thing, distilled)
- **Keep main green**: required checks + reviews + code owners, admins included.
- **CI gates, CD ships**: thin YAML, thick Fastlane lanes (local == CI).
- **Sign reproducibly** (Match, readonly CI), **secrets least-privilege + rotated**, **prod
  human-gated**.
- **Automate versioning**; tag every release; store its artifacts.
- **Plan rollback before you need it**: phased release + feature flags + stored builds.
- **Fast feedback**: cache, parallelize, shard, cancel stale, right-size runners.
- **Pin everything; turn on the free security wins.**
- **Every incident → a new automated check.** The pipeline should get stronger over time.

---

← Back to the [index](README.md). This completes Parts 1–24.
