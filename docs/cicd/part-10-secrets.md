# Part 10 — Secrets Management

Your pipeline needs things it must **never** put in git: `MATCH_PASSWORD`, the App Store Connect
API key, the Slack webhook, certs-repo access. This part covers where those live, how they're
scoped, how GitHub protects them, and how to inject them — especially the tricky bit of turning a
binary `.p8` key file into a secret.

## 10.1 What counts as a secret

```
 NEVER in git:                         OK in git (not secret):
 ───────────                           ──────────────────────
 MATCH_PASSWORD                        bundle ids, team ids (Appfile)
 ASC API key (.p8 + ids)               scheme names, xcconfig non-secret values
 certs-repo deploy key / token         API *base URLs* (usually)
 Slack/Teams webhook URL               public config / feature-flag defaults
 Firebase service account json         the Fastfile / workflows themselves
 signing cert password
```
Rule of thumb: **if leaking it lets someone impersonate you, ship as you, or spend your money — it's
a secret.**

## 10.2 Where GitHub stores secrets (3 scopes)

```
 Organization secrets   ── shared across many repos (e.g. one ASC key for the org)
        │                   scoped to selected repos; great for fleets
 Repository secrets     ── this repo only (most common)
        │
 Environment secrets    ── tied to a named "Environment" (e.g. `production`)
                           can require REVIEWERS + wait timers before a job may read them
```

- **Repository secrets** — the default home for `MATCH_PASSWORD`, `ASC_*`, `SLACK_WEBHOOK`.
- **Organization secrets** — when the same secret serves many apps; set once, share to selected
  repos.
- **Environment secrets** — the power feature: attach the *production* signing/upload secrets to a
  `production` **environment** that **requires a human approval** before the deploy job runs. This
  is how you gate App Store releases (Part 16/21).

```yaml
jobs:
  release:
    environment: production        # ← unlocks env secrets only after required reviewers approve
    runs-on: macos-14
    steps:
      - run: bundle exec fastlane release
        env:
          ASC_KEY_P8: ${{ secrets.ASC_KEY_P8 }}   # resolved from the `production` environment
```

## 10.3 How GitHub protects them

- **Encrypted at rest**; only decrypted into a job's environment at runtime.
- **Masked in logs** — if a secret's value appears in output, GitHub replaces it with `***`.
  (Don't rely on this for derived values — see mistakes.)
- **Not exposed to fork PRs** — a `pull_request` from a fork runs without your secrets, so a
  malicious PR can't exfiltrate them (Part 2).
- **`GITHUB_TOKEN`** is a special auto-generated, per-run secret scoped by your `permissions:`
  block — use it for Danger/PR comments instead of a personal token.

## 10.4 Injection — getting a secret into the build

Secrets reach your tools as **environment variables**:
```yaml
- name: Beta
  run: bundle exec fastlane beta
  env:
    MATCH_PASSWORD:                ${{ secrets.MATCH_PASSWORD }}
    MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
    ASC_KEY_ID:                    ${{ secrets.ASC_KEY_ID }}
    ASC_ISSUER_ID:                 ${{ secrets.ASC_ISSUER_ID }}
    ASC_KEY_P8:                    ${{ secrets.ASC_KEY_P8 }}
    SLACK_URL:                     ${{ secrets.SLACK_WEBHOOK }}
```
The Fastfile reads `ENV["ASC_KEY_ID"]` etc. (Part 8). Map secret → env in the workflow; the lane
stays machine-agnostic.

## 10.5 The binary-file problem: the App Store Connect `.p8` key

GitHub Secrets hold **strings**, but the ASC API key is a file (`AuthKey_XXXX.p8`). Two clean
patterns:

**Pattern A — base64 the file into a string secret (recommended).**
```bash
# once, locally:
base64 -i AuthKey_ABC123.p8 | pbcopy        # paste into secret ASC_KEY_P8
```
Then either let Fastlane decode it (`is_key_content_base64: true`, as in our Fastfile), or
materialize it at runtime with a script:

[`Scripts/decode_secrets.sh`](../../Scripts/decode_secrets.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/private_keys"
echo "$ASC_KEY_P8" | base64 --decode > "$HOME/private_keys/AuthKey_${ASC_KEY_ID}.p8"
```

**Pattern B — store the raw PEM contents** and pass `key_content` directly (no file). Works too;
base64 just avoids newline/encoding surprises in the secrets UI.

## 10.6 The certs-repo credential (for Match)

Match clones a private repo (Part 9). Give the runner read access without a personal account:
- **`MATCH_GIT_BASIC_AUTHORIZATION`** — base64 of `username:personal_access_token`, scoped to
  read that one repo, **or**
- an **SSH deploy key** (read-only) added to the certs repo and loaded via `webfactory/ssh-agent`.

Prefer a **deploy key or fine-grained PAT** limited to the single certs repo — least privilege
(Part 23).

## 10.7 Diagram — the full secret flow

```
 Developer (once)                 GitHub Secrets store              Runner (per job)
 ───────────────                  ────────────────────              ────────────────
 base64 .p8  ───────────────────▶ ASC_KEY_P8 (encrypted) ──┐
 MATCH_PASSWORD ────────────────▶ MATCH_PASSWORD          ─┼─ decrypt ─▶ env vars ─▶ Fastfile
 certs PAT ─────────────────────▶ MATCH_GIT_BASIC_AUTH    ─┘             (masked in logs)
                                                                          │
                                                            decode_secrets.sh → ~/private_keys/*.p8
```

## 10.8 Common mistakes
- **`echo`-ing a secret** (or a value derived from it) → may bypass masking and leak. Never print
  secrets, even "for debugging."
- **Committing the `.p8`/cert/`.env`** → instant compromise. Add to `.gitignore`; if leaked, rotate
  immediately.
- **Using a personal Apple ID + password** instead of an ASC API key → 2FA breaks headless CI and
  the password is over-privileged.
- **A broad PAT** for the certs repo → if leaked it touches everything. Scope to one repo, read
  only.
- **Putting prod secrets in repo scope with no gate** → any merge can ship. Use an **environment**
  with required reviewers for release.

## 10.9 Debugging
- Don't print the secret — print a **fingerprint**: `echo "${ASC_KEY_P8:0:6}…(${#ASC_KEY_P8} chars)"`
  to confirm it's set without leaking it.
- Check it's mapped in `env:` for the *right* job (env doesn't inherit across jobs).
- For env-scoped secrets: confirm `environment:` is set on the job and approvals are satisfied.
- Match auth failing → verify `MATCH_GIT_BASIC_AUTHORIZATION` decodes to valid `user:token` and the
  token can clone the certs repo.

## 10.10 Best practices
- **Least privilege + least scope**: smallest token, narrowest repo/secret scope, env-gated for
  prod.
- **ASC API key over Apple-ID password**, always; base64 the `.p8`.
- **Rotate on a schedule and on offboarding** (Part 23); treat any leak as "rotate now."
- **Never echo secrets**; print fingerprints if you must verify presence.
- **Gate production secrets behind a GitHub Environment** with required reviewers.

---

**Next:** [Part 11 — Testing](part-11-testing.md): unit/UI/snapshot/integration tests, coverage,
parallelism, and reports in CI.
