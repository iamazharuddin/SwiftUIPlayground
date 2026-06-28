# Part 18 — Rollback Strategy

Things break in production. A mature pipeline plans for "undo" *before* it's needed. The catch:
**iOS rollback is different** — you can't just redeploy yesterday's server. Apple controls
distribution, so "rollback" means specific, pre-planned moves. This part covers what to do when a
deployment fails or a bad build reaches users.

## 18.1 The iOS rollback reality

```
 Server app:  bad deploy → redeploy previous container → fixed in minutes (true rollback)

 iOS app:     bad build is LIVE on the App Store
              → you CANNOT "un-release" a version to users who already updated
              → options are: halt spread, expedite a fix, or pull the version
```

Why: once a user has updated to 1.4.0, Apple won't downgrade them. So iOS "rollback" is really
**damage control + fast-forward fix**, plus prevention (phased release).

## 18.2 The toolbox (fastest → slowest)

```
 ① Pause phased release        (if you used it — Part 16)   seconds, no review
 ② Remove from sale / pull     the broken version            minutes, stops NEW downloads
 ③ Feature-flag kill switch    disable the bad feature       seconds, server-controlled
 ④ Expedited review hotfix     ship 1.4.1 fast               hours (expedite request)
 ⑤ Re-promote a known-good     resubmit a prior good build   hours (still needs review)
```

### ① Pause the phased release (best case)
If you shipped with `phased_release: true`, only a small % of users have the bad build. **Pause it
in App Store Connect** → no more users get it while you fix forward. This is the single biggest
argument for always using phased releases (Part 16).

### ② Remove the version from sale
Pull the current version so **new** downloads stop (existing users keep it). Buys time; doesn't
fix installed users.

### ③ Feature-flag kill switch (prevention that doubles as rollback)
If the risky feature is behind a **remote feature flag** (Part 19), you flip it off server-side and
the bad code path goes dark **without any App Store action**. This is the fastest real "rollback"
iOS has — which is why important features ship flag-gated.

### ④ Expedited hotfix
Branch `hotfix/1.4.1` off the release tag, fix, tag `v1.4.1`, run `release.yml`, and **request an
expedited review** from Apple. Hours, not days — but still a review.

### ⑤ Re-promote a known-good build
Because you stored **every release `.ipa` + dSYMs on the GitHub Release** (Part 16), you can grab
the last good binary. Note: you still must **resubmit** it as a new version/build to ASC (Apple
won't let you re-point users at an old build) — but having the exact artifact removes rebuild risk.

## 18.3 What CI/CD pre-builds so rollback is possible

Rollback isn't a button you bolt on after an incident — it's the payoff of habits from earlier
parts:

| Habit | Part | Enables |
|-------|------|---------|
| Phased release | 16 | pause-the-rollout |
| Release `.ipa`+dSYMs on GitHub Release | 14,16 | re-promote a known-good build |
| Immutable git tags per release | 16,20 | branch a precise hotfix |
| Feature flags | 19 | server-side kill switch |
| Build artifacts tied to commit | 14 | reproduce/inspect any shipped build |

## 18.4 "Deployment failed" (the CI side)

If the *pipeline* fails mid-deploy (not a bad live build):

```
 fastlane release fails at...
   ├─ build/sign step   → nothing shipped; fix and re-run. Safe.
   ├─ upload step       → maybe a partial upload; ASC dedupes by build number.
   │                      Re-run with the SAME tag — increment build number handles dupes.
   └─ after submit      → it's in review; cancel in ASC if needed, fix, resubmit.
```
Because the lane is **idempotent-ish** (auto build-number bump, Match readonly), re-running is
usually safe. The artifact + tag mean you always know exactly what state you're in.

## 18.5 A hotfix workflow (ties to branching, Part 24)

```
 main/release tag v1.4.0  ──(bug found)──┐
                                          ▼
                            git checkout -b hotfix/1.4.1 v1.4.0
                                          │  fix + test
                                          ▼
                            PR → fast review → merge
                                          │
                            git tag v1.4.1 && push  ─▶ release.yml (gated) ─▶ expedited review
                                          │
                            also merge hotfix back into develop (don't lose the fix)
```

## 18.6 Common mistakes
- **No phased release** → 100% of users get the bad build instantly; nothing to pause.
- **No feature flags on risky features** → your only option is a multi-hour review.
- **Not storing release artifacts** → can't re-promote; must rebuild from a tag under pressure.
- **Forgetting to merge the hotfix back to develop** → the bug returns in the next release.
- **`automatic_release: true`** → bad build goes fully live with no human checkpoint (Part 16).

## 18.7 Debugging / incident flow
1. **Confirm scope** — crash rate / affected version (ASC + crash tool via dSYMs).
2. **Stop the bleeding** — pause phased release / flip feature flag.
3. **Decide** — flag fix (instant) vs hotfix release (hours).
4. **Ship the fix** — hotfix branch → tag → gated `release.yml` → expedite.
5. **Backport** — merge hotfix into develop.
6. **Postmortem** — why did CI not catch it? Add a test/gate (Parts 11–12) so it can't recur.

## 18.8 Best practices
- **Phased release + feature flags = your real rollback levers.** Build them in before you need
  them.
- **Every release is an immutable tag with stored artifacts** → precise, reproducible hotfixes.
- **Keep the deploy lane idempotent** so re-running after a failed deploy is safe.
- **Always backport hotfixes to develop.**
- **Turn every incident into a new automated check** so the pipeline gets stronger each time.

---

**Next (Batch 7):** [Part 19 — Environment Management](part-19-environments.md): schemes, build
configs, and `.xcconfig` for Dev/QA/Staging/Production — with real config files.
