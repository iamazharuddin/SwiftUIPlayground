# Part 1 — CI/CD Fundamentals

## 1.1 What is CI (Continuous Integration)?

**Concept.** CI is the practice of automatically **building and testing your code every time
it changes**, on a neutral machine that is not your laptop.

**Why it exists.** Before CI, teams "integrated" their work occasionally — everyone coded for
two weeks, then spent days merging and fixing the explosion of conflicts and broken builds
("integration hell"). CI flips this: integrate *continuously*, in small pieces, and let a robot
prove each piece still builds and passes tests within minutes.

**The core promise:** *"main is always green."* At any moment, the main branch compiles and its
tests pass, because nothing gets in without proving that first.

```
Without CI                          With CI
──────────                          ───────
dev A ─┐                            dev A ─┐
dev B ─┼─ 2 weeks ─▶ BIG MERGE      dev B ─┼─ small PR ─▶ robot builds+tests ─▶ merge
dev C ─┘            💥 chaos         dev C ─┘            ✅ green                  ✅
```

**For iOS specifically**, CI means: on every push/PR, a Mac in the cloud runs
`xcodebuild`, compiles all targets, runs your XCTest unit/UI tests, and runs linters — and
reports pass/fail back onto the PR before a human reviews it.

## 1.2 What is CD (Continuous Delivery / Deployment)?

**Concept.** CD extends CI past "it builds" into "it ships." After the build is green, the same
automation **packages and delivers** the app to where testers or users can get it.

Two flavors — the distinction matters:

- **Continuous *Delivery*** — every green build is *automatically prepared* for release (signed
  `.ipa`, uploaded to TestFlight), but a **human clicks the final button** to push to users.
- **Continuous *Deployment*** — no human button; green build goes all the way to users
  automatically.

**iOS reality:** true Continuous *Deployment* to the App Store is essentially impossible because
**Apple's App Review is a mandatory human/automated gate** (hours to days). So iOS teams do
Continuous *Delivery*: automate everything up to and including the TestFlight upload and even the
"submit for review," but the actual public release is a deliberate, human-approved step.

```
   CI                    Continuous Delivery                 Continuous Deployment
 ┌──────┐   ┌───────────────────────────────────┐   ┌──────────────────────────────┐
 │build │──▶│ sign ▶ .ipa ▶ TestFlight ▶ [HUMAN │   │ ... ▶ App Store (auto, no    │
 │ +test│   │                       approves]   │   │       human) — rare on iOS   │
 └──────┘   └───────────────────────────────────┘   └──────────────────────────────┘
```

## 1.3 Why companies use CI/CD

| Pain without it | What CI/CD gives you |
|---|---|
| "Works on my machine" | Builds on a clean, identical machine every time → reproducible |
| Bugs found late, in QA or prod | Bugs found in minutes, on the PR, by the author |
| Manual, error-prone releases | One automated, repeatable, logged release path |
| "Who broke main?" | Every change is gated; main stays green |
| Release takes a senior dev a full day | Release is a button; anyone can trigger it |
| No record of *what* shipped | Every build is an artifact tied to a commit/tag |

The deeper payoff is **speed with confidence**: small changes ship often, and the automation —
not human vigilance — guarantees quality. This is what lets a 200-engineer org ship a weekly
release without chaos.

## 1.4 How developers use it every day

You barely "use" CI/CD directly — it reacts to your normal git workflow:

```
You, on a Tuesday:
  1. git checkout -b feature/login-screen
  2. ...write code, commit...
  3. git push                         ──▶ CI runs lint+build+test on your branch
  4. open a Pull Request              ──▶ CI runs the full PR pipeline; results show on the PR
  5. teammate reviews + approves
  6. you click "Merge"                ──▶ CI runs on main; maybe auto-deploys a beta to TestFlight
  7. Slack: "✅ Build 412 on TestFlight"
```

The mental model: **you push code; the pipeline gives you a verdict.** Red = fix it. Green =
proceed. You never run the release steps by hand.

## 1.5 The lifecycle — what happens at each stage

### After `git push`
```
git push ─▶ GitHub stores commit ─▶ "push" event fires ─▶ Actions starts a workflow
        ─▶ runner: checkout ▶ resolve SPM ▶ swiftlint ▶ build ▶ unit tests ─▶ ✅/❌ on commit
```
Fast feedback loop. Usually lint + build + unit tests (not the slow UI tests) so you hear back
in a few minutes.

### After you open a Pull Request
```
open PR ─▶ "pull_request" event ─▶ full pipeline:
          lint ▶ build ▶ unit tests ▶ UI tests ▶ code coverage ▶ Danger
        ─▶ status checks appear on the PR (✅ required checks must pass)
        ─▶ Danger bot leaves comments (missing tests? big diff? no changelog?)
```
The PR becomes a dashboard: reviewers see green checks before reading code. Branch-protection
rules can **block merge** until all required checks pass.

### After someone approves the MR/PR
Approval is a *human* signal; it does **not** itself build anything. But it unlocks the merge
button (often "≥1 approval **and** all checks green" is required). The combination — approved +
green — is the gate.

### After merge into main/develop
```
merge ─▶ "push to main" event ─▶ deploy pipeline:
        build ▶ test ▶ archive ▶ sign ▶ export .ipa ▶ upload TestFlight ▶ notify
```
This is where **CD** kicks in: the merged code is turned into a real, installable beta.

### Before an App Store release
```
release branch / git tag v1.4.0
   ▶ archive (Release config, Production scheme)
   ▶ sign with Distribution cert + App Store profile
   ▶ upload to App Store Connect
   ▶ set metadata / release notes / screenshots
   ▶ submit for review
   ▶ [Apple reviews] ▶ [HUMAN clicks "Release"] ▶ live
```

## 1.6 Common mistakes (beginners)

- **Treating CI as "just run tests."** CI is the *gate* that keeps main shippable; tests are one
  check among lint, build, coverage, and signing.
- **Putting secrets in the repo.** Certificates, API keys, passwords never live in git — they go
  in GitHub Secrets (Part 10).
- **Letting CI be flaky.** A pipeline that fails randomly trains the team to ignore red. Flaky =
  broken; fix or quarantine it.
- **Slow pipelines.** If feedback takes 40 minutes, people stop waiting for it. Speed is a
  feature (Parts 13, 22).

## 1.7 Best practices (what seniors do)

- **Keep main green, always.** Required status checks + branch protection, no exceptions.
- **Fail fast, fail loud.** Cheap checks (lint) before expensive ones (UI tests). First failure
  stops the line.
- **One source of truth for build logic** (Fastlane lanes) used identically by humans and CI — so
  "it works in CI but not locally" can't happen.
- **Everything reproducible from a commit.** Given a commit SHA, the pipeline can rebuild the exact
  same artifact.

---

**Next:** [Part 2 — GitHub Internals](part-02-github-internals.md): exactly how a `git push`
becomes a running job.
