# Part 2 — GitHub Internals: from `git push` to a running job

This part demystifies the machinery. By the end you'll know exactly what GitHub does between you
pressing Enter on `git push` and a Mac in the cloud compiling your app.

## 2.1 The full flow

```
 Developer
    │  git push (or: open PR, merge, create tag)
    ▼
 GitHub Repository  ─────────────  stores the new commits/refs
    │
    ▼
 Event is generated      e.g. "push", "pull_request", "workflow_dispatch", "release"
    │
    ▼
 Event Router            GitHub scans .github/workflows/*.yml for workflows whose `on:` matches
    │
    ▼
 Workflow Run created    one run per matching workflow; status = queued
    │
    ▼
 Job Scheduler           each job needing `runs-on: macos-14` waits for a free runner of that type
    │
    ▼
 Runner (a clean macOS VM)   picks up the job, runs each step, streams logs back
    │
    ▼
 Status reported          ✅/❌ posted back onto the commit & PR as a "check run"
```

## 2.2 How GitHub detects a push

When you `git push`, your git client uploads objects (commits, trees, blobs) and asks GitHub to
move a **ref** (e.g. `refs/heads/feature/login`) to point at the new commit. The moment that ref
moves, GitHub's backend records it and emits an internal **event**. There is no polling — it's
push-based and immediate.

The same mechanism fires for other actions, each with its own event **type**:

| You do this | Event type | Typical use |
|---|---|---|
| `git push` to a branch | `push` | branch CI (lint/build/test) |
| Open / update a PR | `pull_request` | full PR validation |
| Merge a PR | `push` (to base branch) | deploy/beta pipeline |
| Create a tag `v1.4.0` | `push` (tag) or `release` | App Store release pipeline |
| Click "Run workflow" | `workflow_dispatch` | manual releases |
| A schedule (cron) | `schedule` | nightly builds |

## 2.3 What "triggers" Actions

GitHub looks **only inside `.github/workflows/`** in the commit that was pushed, reads each
`*.yml` file's `on:` block, and asks: *does this event match?* If yes, it creates a **workflow
run**.

```yaml
# .github/workflows/ci.yml  (minimal example — full keyword tour is Part 4)
on:
  push:
    branches: [ "feature/**", "develop" ]   # push to these branches → run
  pull_request:
    branches: [ "develop", "main" ]          # PRs targeting these → run
```

Internals worth knowing:

- The workflow file is read **from the ref that triggered it** (with one exception: for
  `pull_request`, it runs the workflow as defined in the *base* branch, for security — so a
  malicious PR can't rewrite the pipeline to steal secrets).
- One event can start **many** workflow runs (e.g. `ci.yml` and `danger.yml` both match a PR).
- Each run gets a unique ID and a fresh, isolated execution.

## 2.4 Runners — who actually does the work

A **runner** is a virtual machine that executes your job's steps. For iOS you need a **macOS
runner** because `xcodebuild`, Xcode, and the iOS Simulator only exist on macOS (Part 6 goes
deep).

```
 Workflow run (queued)
   ├─ job: lint        runs-on: macos-14  ─▶ Scheduler finds a free macOS VM ─▶ runs
   ├─ job: test        runs-on: macos-14  ─▶ (can run in parallel on another VM)
   └─ job: deploy      needs: [test]      ─▶ waits until `test` succeeds, then schedules
```

**How a runner receives a job:** GitHub-hosted runners are managed by GitHub. When a job is
ready, the scheduler provisions a **brand-new, clean VM** from an image (Xcode + tools
pre-installed), hands it the job definition, and the runner agent executes steps top-to-bottom,
streaming logs to the UI in real time. When the job ends, **the VM is destroyed** — nothing
persists to the next job (this is why caching and artifacts exist; Parts 13–14).

## 2.5 Job scheduling, parallelism, and the workflow lifecycle

**Lifecycle of one run:**
```
queued ─▶ in_progress ─▶ (each job: queued ▶ in_progress ▶ completed) ─▶ completed
                                                                           result: success | failure | cancelled
```

**Parallelism rules:**
- **Jobs in the same workflow run in parallel by default.** They only serialize when you declare
  dependencies with `needs:` (Part 4).
- A **matrix** (Part 4/22) expands one job into N parallel jobs (e.g. test on iPhone 15 *and*
  iPhone SE simultaneously).
- Parallelism is bounded by your plan's **concurrent-runner limit** and by macOS runner
  availability; excess jobs sit in `queued`.

```
time ──────────────────────────────────────────▶
 lint   ██████
 build  ████████
 test   ▏        ████████████        (needs: build → starts after build)
 ui     ▏        ████████████████
 deploy ▏                        ████ (needs: test,ui)
        └ parallel where possible ┘
```

## 2.6 The four event flows you'll live in

```
① Push to feature branch        ② Open / update PR
   push event                       pull_request event
   → fast CI (lint,build,unit)      → full CI + Danger + coverage
   → ✅/❌ on the commit             → required checks gate the merge button

③ Merge to develop/main         ④ Tag v1.4.0 / GitHub Release
   push event (base branch)         push(tag) / release event
   → beta pipeline                  → App Store pipeline
   → archive,sign,TestFlight        → archive Release, upload, submit for review
```

## 2.7 Common mistakes

- **Workflow not triggering.** Usually the file isn't in `.github/workflows/` *on the pushed
  branch*, or the `on:` `branches:` filter doesn't match. The workflow must exist in the commit
  you push.
- **Expecting state to persist between jobs.** Each job is a fresh VM. Passing files between jobs
  needs `actions/upload-artifact` / `download-artifact` (Part 14).
- **Editing a PR's workflow expecting new secrets access.** `pull_request` from forks runs with
  restricted permissions and no secrets, by design.
- **Assuming order.** Jobs without `needs:` may start in any order / simultaneously. Never rely on
  implicit ordering.

## 2.8 Debugging

- **Actions tab → the run → the job → expand each step.** Logs stream live and persist.
- **Re-run failed jobs** to test flakiness; **re-run with debug logging** for verbose output.
- Set repo secrets `ACTIONS_RUNNER_DEBUG=true` and `ACTIONS_STEP_DEBUG=true` for deep traces.
- For "why didn't it trigger?": check the **`on:` filters** and that the file parses (a YAML
  syntax error silently disables the workflow — validate with `actionlint`).
- SSH into a stuck run with a debug action (e.g. `mxschmitt/action-tmate`) — use sparingly, never
  on workflows with production secrets.

## 2.9 Best practices

- **Separate workflows by purpose** (`ci.yml`, `beta.yml`, `release.yml`) instead of one giant
  file with lots of `if:` — easier to reason about and to scope permissions.
- **Use `concurrency:`** (Part 4) to auto-cancel superseded runs when you push twice quickly —
  saves runner minutes (macOS minutes are expensive; Part 6).
- **Pin third-party actions to a SHA**, not a moving tag, for supply-chain safety (Part 23).
- **Least-privilege `permissions:`** at the top of every workflow (Part 4/23).

---

**Next:** [Part 3 — Repository Structure](part-03-repository-structure.md): the folders and files
a production iOS repo needs, and why each exists.
