# Part 23 — Security

A CI/CD pipeline is a high-value target: it holds signing certs, store credentials, and can ship
code to millions of devices. This part hardens it — credentials, supply chain, permissions, and the
build itself.

## 23.1 The threat model

```
 What an attacker wants from your pipeline
 ─────────────────────────────────────────
 • the Distribution cert + ASC key  → ship malware AS you
 • secrets (Match pw, API keys)     → impersonate, pivot
 • a malicious 3rd-party action     → exfiltrate all of the above
 • a poisoned dependency            → ship a backdoor to users
 • write access to main             → inject code that CI then signs+ships
```
Defense is layered: protect secrets, the supply chain, the permissions, and the branch.

## 23.2 Secret & certificate rotation
- **Rotate on a schedule** (e.g. ASC API keys, Match password) and **immediately on offboarding** or
  any suspected leak. A secret that never rotates is a secret that eventually leaks and stays
  useful.
- **Certificates expire (~1 year)** — track expiry; rotate before they lapse (a surprise expiry
  breaks every build). Match makes re-issuing + redistributing one command.
- **Never echo secrets** (Part 10); print fingerprints. Treat any accidental log exposure as
  "rotate now."
- **Scope minimally**: a fine-grained PAT limited to the *one* certs repo, read-only; an ASC key
  with only the roles it needs.

## 23.3 Least privilege (permissions)
- **`permissions:` block** on every workflow, default `contents: read`; add the minimum (Part 4).
  A compromised step can only do what the token allows.
- **GitHub Environments** for prod secrets with **required reviewers** (Parts 10, 16) — a human
  approves before signing/upload secrets are exposed.
- **Fork PRs get no secrets** by default (Part 2) — don't defeat this with `pull_request_target`
  unless you fully understand it (it's a classic exfiltration vector).
- **Self-hosted runners**: never use them on public repos (a fork PR could run arbitrary code on
  your hardware); isolate, patch, and least-privilege them (Part 6).

## 23.4 Supply-chain security (dependencies & actions)
- **Pin third-party actions to a full commit SHA**, not a moving tag:
  ```yaml
  - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
  ```
  A tag like `@v4` can be re-pointed to malicious code; a SHA can't.
- **Pin tool & gem versions** (`Gemfile.lock`, `.xcode-version`, brew formula versions) — Part 3.
- **Dependency scanning**: enable **Dependabot** (updates + alerts) and review SPM/gem advisories.
- **Vulnerability scanning**: GitHub **code scanning** (CodeQL) and **secret scanning** (catches
  committed keys). Turn on **push protection** so secrets can't even be pushed.
- **Verify what you fetch**: don't `curl | bash` from untrusted sources in CI.

## 23.5 Signed & verifiable builds
- **Code signing** (Part 9) is itself a security control — only your Distribution cert can produce a
  store-accepted build. Guard that cert (Match, encrypted, `readonly` on CI).
- **Verify signing** in CI before upload: `codesign --verify --deep --strict` and check the
  embedded profile, so a misconfigured/over-entitled build fails fast.
- **Provenance/attestations** (optional, advanced): generate build provenance
  (`actions/attest-build-provenance`) so a binary can be traced to the exact commit + workflow that
  built it.

## 23.6 Branch protection (Part 21 = security control)
Write access to `main` ⇒ ability to ship signed code. So:
- Require PRs + reviews + code-owner approval + green required checks (Part 21).
- **Include administrators**; restrict who can push/merge.
- **Require signed commits** (optional) for authorship integrity.
- Protect tags (`v*`) too, since they trigger releases.

## 23.7 Defense-in-depth checklist
```
 [ ] permissions: contents: read by default, minimal additions
 [ ] prod secrets behind an Environment with required reviewers
 [ ] all 3rd-party actions pinned to SHAs
 [ ] Gemfile.lock / Xcode / tool versions pinned
 [ ] Dependabot + CodeQL + secret scanning (push protection) on
 [ ] Match certs in a separate private repo, encrypted, readonly on CI
 [ ] ASC API key (scoped) instead of Apple-ID password; rotated on schedule
 [ ] never echo secrets; rotate on leak/offboarding
 [ ] branch + tag protection, include admins
 [ ] no self-hosted runners on public repos
```

## 23.8 Common mistakes
- **Moving-tag actions** (`@v4`/`@main`) → supply-chain hijack risk.
- **`permissions: write-all`** or default broad token → over-privileged.
- **`pull_request_target` + checkout of PR head** → classic secret-exfiltration hole.
- **Long-lived, broad PATs / Apple-ID passwords** → big blast radius; use scoped, rotating creds.
- **Secrets in `.xcconfig`/repo** → committed forever in history; rotate and purge.
- **No secret-scanning push protection** → a key gets committed, then it's public.

## 23.9 Debugging / verifying
- Review the workflow's effective `permissions` in the run logs.
- `git log -p` / secret-scanning alerts to find committed secrets; rotate any found.
- `codesign -dvvv <App>.app` and `security cms -D -i embedded.mobileprovision` → verify identity +
  entitlements.
- Dependabot/CodeQL alerts in the Security tab; triage regularly.

## 23.10 Best practices
- **Least privilege everywhere**: tokens, secrets scope, runner access, branch write.
- **Pin everything** (actions to SHAs, tools/gems to versions).
- **Gate prod behind human-approved Environments.**
- **Rotate on schedule + on leak/offboarding; never echo secrets.**
- **Turn on the free wins**: Dependabot, CodeQL, secret scanning + push protection, branch/tag
  protection.
- **Verify signing and (optionally) attest provenance** before shipping.

---

**Next:** [Part 24 — Real Enterprise Workflow](part-24-enterprise-workflow.md).
