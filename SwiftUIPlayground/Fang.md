//
//  Fang.md
//  SwiftUIPlayground
//
//  Senior Staff engineer prep — Amazon, Google, Meta, Netflix, Apple
//  Plus: crash debugging when not every user can reproduce.
//

# Senior Staff engineer prep (Fang)

---

## 7. Crash debugging when most users never reproduce

“Does not reproduce on my device” is normal at scale. Senior Staff work is to turn crashes into **falsifiable hypotheses** and **measurable risk reduction**, not magic local repro.

### A. Accept the base rate

- A crash affecting **0.01%** of sessions can still be **thousands** of events per day; rarity per user ≠ unimportant.
- Many crashes are **environment conditional**: memory pressure, disk space, OS version, locale/RTL, accessibility settings, slow CPU, flaky network, MDM profiles, third-party keyboards, app extensions.

### B. Make the crash report legible

- **Symbolicate** reliably: dSYM UUID matches binary; bitcode/strip settings understood; CI uploads symbols to your crash backend.
- **Bucket smartly**: group by faulting thread + top app frames + signal/exception type; de-noise with version and OS filters.
- Tag builds with **git SHA**, **feature flags**, and **config** (remote config revision).

### C. Add telemetry that survives the crash (before and after)

- **Breadcrumbs** (rate-limited, privacy-safe): last N screens, navigation stack ids, experiment bucket, network reachability class, memory warning count, thermal state, low-power mode, disk space bucket.
- **Non-fatal logging** for “this should never happen” invariants (assert in debug, log in prod with sampling).
- **File/DB integrity checks** after migrations; log schema versions.

### D. Narrow with cohort analysis

- Slice by: **OS minor**, **device model**, **RAM tier**, **app version**, **locale**, **fresh install vs upgrade**, **time since install**, **session length**.
- If only **upgrades** crash: suspect migration, cached state, or flag rollout.

### E. Reproduce statistically, not mystically

- **Stress harness**: navigation fuzzing, rapid background/foreground, repeated cold start, low-memory simulator, airplane mode toggling.
- **Canary + staged rollout**: prove crash rate delta against control; fastest way to confirm a fix or a suspect change.
- **Binary search**: bisect commits between last known good and spike; bisect feature flags.

### F. Tooling for the “impossible”

- **Address Sanitizer / Thread Sanitizer** builds for internal dogfood; catch classes of `EXC_BAD_ACCESS` and races before production.
- **Guard malloc**, **malloc stack**, zombies (where applicable) for internal repro attempts.
- **Core dumps** are not iOS end-user standard; lean on **rich crash reports** + **on-device diagnostics** you control.

### G. Definition of done (Staff-level)

- Documented **root cause** (or strongest evidence with residual risk called out).
- **Guard** (code or kill switch) + **metric movement** in crash backend + **monitoring** for recurrence.
- **Postmortem**: what signals were missing; what you will add so the *next* rare crash costs less.

---
