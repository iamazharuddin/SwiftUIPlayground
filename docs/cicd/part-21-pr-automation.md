# Part 21 — Pull Request Automation

This is where CI becomes a **gate**, not just a reporter. We wire required checks, code-review
rules, and merge protection so that the only way into `main`/`develop` is "green + reviewed."
Real file: [`.github/CODEOWNERS`](../../.github/CODEOWNERS).

## 21.1 The gate

```
 open PR ─▶ workflows auto-trigger (Part 2) ─▶ status checks appear on the PR
         ─▶ Danger comments (Part 12)        ─┐
         ─▶ CODEOWNERS auto-requests reviewers │  branch protection requires:
         ─▶ reviewers approve                  ├─▶ ✅ required checks pass
                                               ├─▶ ✅ ≥N approvals (incl. code owners)
                                               └─▶ ✅ branch up to date
                                                      │
                                                      ▼
                                                 Merge enabled
```
The merge button stays disabled until every condition is met — enforced by GitHub, not by
convention.

## 21.2 Automatic workflow triggers
Already built (Part 2/4): `on: pull_request` runs `ci.yml` (lint ∥ build+test → Danger) for every
PR into `develop`/`main`. No one has to "kick off" CI — opening/updating the PR does.

## 21.3 Required status checks
A **status check** is a job's pass/fail reported onto the PR's head commit. Branch protection lets
you mark specific checks **required** — the merge button is blocked until they're green.

Configured in **Settings → Branches → Branch protection rule** for `main`/`develop`:
- Require status checks to pass: `lint`, `unit_test`, `danger`.
- Require branches to be **up to date** before merging (so checks ran against the latest base).

> Check names come from the **job names** in your workflow. Rename a job → update the required-check
> list or merges silently stop being gated on it.

## 21.4 Code review enforcement — CODEOWNERS
[`.github/CODEOWNERS`](../../.github/CODEOWNERS) maps paths → owners; GitHub **auto-requests** the
right reviewers and (with "Require review from Code Owners") **blocks merge** without their approval.
```
# .github/CODEOWNERS
*                       @acme/ios-team
/.github/               @acme/devops
/fastlane/              @acme/devops
/Configurations/        @acme/ios-leads
/App/Sources/Payments/  @acme/payments-team
```
- A PR touching `App/Sources/Payments/` requires a **@acme/payments-team** approval — domain
  experts gate their domain.
- Pair with branch protection: "Require a pull request before merging" + "Require approval of the
  most recent push" + "Require review from Code Owners."

## 21.5 Danger comments (recap, Part 12)
Danger runs in `ci.yml` and posts inline PR feedback (no tests added, big PR, WIP title, no
changelog). `fail()` rules surface as a failing check that can be **required** → process violations
block merge, automatically and impersonally.

## 21.6 Build validation
The PR must prove it **builds and tests green** before merge — that's the `unit_test` job. UI tests
can be required too, or deferred to merge for speed (Part 11). The principle: **main is always
green** (Part 1) because nothing merges un-green.

## 21.7 Merge protection rules (the full set)
A solid `main`/`develop` rule:
- ✅ Require a PR before merging (no direct pushes).
- ✅ Require approvals (e.g. 1–2), dismiss stale approvals on new commits.
- ✅ Require review from Code Owners.
- ✅ Require status checks: `lint`, `unit_test`, `danger` (+ branch up to date).
- ✅ Require conversation resolution.
- ✅ Require linear history (optional; pairs with squash merges).
- ✅ Include administrators (so the rules apply to everyone).
- ✅ Restrict who can push / who can merge (optional).

## 21.8 Auto-merge & housekeeping
- **Auto-merge** — enable it on a PR; GitHub merges automatically once all required checks + reviews
  pass. Great with slow iOS checks: approve, walk away, it merges when green.
- **Dependabot** (`.github/dependabot.yml`) — automated dependency-update PRs that run the same CI.
- **Stale/PR labeler actions** — optional hygiene.

## 21.9 Common mistakes
- **Checks exist but aren't *required*** → red PRs can still merge; the gate is decorative.
- **Renaming a job** without updating required-check names → silent loss of gating.
- **"Include administrators" off** → the rules don't apply to the people most likely to bypass
  them.
- **No "up to date before merge"** → a PR passes against a stale base and breaks `main` after merge.
- **CODEOWNERS without "require code-owner review"** → owners are requested but not enforced.

## 21.10 Debugging
- Merge button blocked but unclear why → the PR's "merge box" lists each unmet requirement.
- Required check never appears → the workflow didn't trigger (Part 2 `on:` filters) or the job
  name ≠ the required-check name.
- CODEOWNERS not requesting anyone → syntax/path error; GitHub shows a CODEOWNERS validity warning
  in the repo's Settings.

## 21.11 Best practices
- **Make the key checks required** (`lint`, `unit_test`, `danger`) + **branch up to date** +
  **code-owner review** — that's the real gate.
- **CODEOWNERS for sensitive paths** (payments, signing, CI config).
- **Include administrators**; no bypass culture.
- **Auto-merge** to ride out slow macOS checks without babysitting.
- **Keep job names stable** (they're your required-check identifiers).

---

**Next (Batch 8):** [Part 22 — Performance Optimization](part-22-performance.md).
