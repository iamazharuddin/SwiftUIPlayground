# Part 13 — Caching

Every job runs on a **fresh VM** (Part 6), so without caching CI re-downloads every Swift package
and rebuilds every dependency on every run — slow and expensive (macOS minutes!). Caching stores
the reusable bits between runs and restores them, turning a cold 12-minute build into a warm
4-minute one.

## 13.1 The model: key, restore, save

```
 job start ─▶ look up cache by KEY
              ├─ exact hit  ─▶ restore files (fast) ─▶ skip the expensive work
              └─ miss       ─▶ try restore-keys (partial) ─▶ do the work ─▶ SAVE under KEY
```
- **`key`** — an exact identifier. If a cache with this key exists, restore it.
- **`restore-keys`** — fallback *prefixes* tried on a miss (a *partial/older* cache is better than
  nothing).
- **save** — `actions/cache@v4` automatically saves at job end **if the key didn't already exist**
  (so caches are immutable per key).

## 13.2 What's worth caching for iOS

| Cache | Path | Keyed by |
|-------|------|----------|
| **Swift Package Manager** | `~/Library/Developer/Xcode/DerivedData/**/SourcePackages` or `~/Library/Caches/org.swift.swiftpm` | `Package.resolved` hash |
| **DerivedData** (build intermediates) | `~/Library/Developer/Xcode/DerivedData` | source/build-settings hash (tricky — see 13.5) |
| **Ruby gems** (fastlane/danger) | `vendor/bundle` | `Gemfile.lock` hash |
| **CocoaPods** (if used) | `Pods/` | `Podfile.lock` hash |
| **Homebrew** (swiftlint/xcbeautify) | brew cache | tool versions |

The golden rule: **the cache key is a hash of the lockfile that determines the content.** If
`Package.resolved` is unchanged, the resolved packages are identical → safe to reuse.

## 13.3 Real config

### SPM (used in our `ci.yml`)
```yaml
- name: Cache Swift Package Manager
  uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
    key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      spm-${{ runner.os }}-
```
- **`key`** changes only when `Package.resolved` changes → new deps = new cache.
- **`restore-keys: spm-macOS-`** → on a miss (deps changed), still restore the *previous* SPM cache
  so only the changed packages re-download.

### Ruby gems — easiest via `setup-ruby`
```yaml
- uses: ruby/setup-ruby@v1
  with:
    bundler-cache: true        # internally caches vendor/bundle keyed by Gemfile.lock
```
This one line replaces a manual `actions/cache` for gems.

### DerivedData (build intermediates) — optional, see caveats
```yaml
- uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: dd-${{ runner.os }}-${{ env.XCODE_VERSION }}-${{ hashFiles('**/*.swift') }}
    restore-keys: |
      dd-${{ runner.os }}-${{ env.XCODE_VERSION }}-
```

## 13.4 Cache invalidation — the hard part

> "There are only two hard things in CS: cache invalidation and naming things."

A cache is **stale** when its key no longer reflects the content. Get the key wrong and you either:
- **under-invalidate** (key too loose) → you restore an *out-of-date* cache → mysterious build
  errors ("works locally, broken in CI"), **or**
- **over-invalidate** (key too tight) → key changes constantly → near-zero hit rate → caching does
  nothing.

Design keys to include **everything that affects the cached content**:
```
SPM cache key       = os + hash(Package.resolved)            # deps depend on the lockfile
DerivedData key     = os + Xcode version + hash(sources)     # build output depends on both
gems key            = os + hash(Gemfile.lock)
```
Including the **Xcode version** matters: a DerivedData cache from Xcode 16.0 is invalid under 16.1.

## 13.5 Why DerivedData caching is risky on iOS

DerivedData holds incremental build state that's **very** sensitive to Xcode version, build
settings, file timestamps, and absolute paths. A subtly-stale DerivedData cache causes
hard-to-debug failures ("undefined symbol," "module not found"). Pragmatic stance:
- **Always cache SPM and gems** — big win, low risk.
- **Be cautious with DerivedData** — cache it only if you measure a real speedup *and* you key it
  tightly (Xcode version + source hash). Many teams skip it on hosted runners and instead rely on
  **self-hosted runners** that keep DerivedData warm naturally (Part 6).

## 13.6 Why caching speeds builds (the math)
```
 cold run:  resolve+download SPM (3m) + build deps (4m) + app build/test (5m) = 12m
 warm run:  restore SPM (20s)        + (deps prebuilt)   + app build/test (4m) ≈ 5m
```
On macOS at ~10× Linux minute cost, shaving 7 minutes off every PR build across a team is large,
recurring savings — and faster feedback (Part 1).

## 13.7 Scope & limits
- Caches are **scoped to a branch**, with reads falling back to the **default branch's** caches —
  so a new feature branch benefits from `develop`'s warm cache.
- There's a **repo-wide cache size budget**; GitHub **evicts least-recently-used** caches when
  full. Don't cache giant useless dirs.
- Caches are **immutable per key** — to "update" a cache you must change the key (that's why keys
  hash lockfiles).

## 13.8 Common mistakes
- **Key without the lockfile hash** (e.g. `key: spm-cache`) → never invalidates → stale deps.
- **Caching DerivedData with a loose key** → flaky "undefined symbol" failures.
- **Forgetting `restore-keys`** → every dep change = full cold download instead of partial.
- **Caching huge dirs** (whole `~/Library`) → blows the budget, evicts useful caches, slows
  save/restore.
- **Expecting cross-job sharing without it** → each job caches independently; the cache is the only
  bridge (besides artifacts).

## 13.9 Debugging
- The cache step logs **"Cache restored from key …"** or **"Cache not found"** — read it to confirm
  hits.
- Hit rate low? Print `hashFiles('**/Package.resolved')` and check the lockfile is committed and
  stable.
- Suspected stale cache causing build errors? Bump a **cache-version prefix** in the key
  (`spm-v2-…`) to force a clean rebuild, or clear caches in the Actions UI.

## 13.10 Best practices
- **Cache SPM + gems always; key by the lockfile hash; add `restore-keys` prefixes.**
- **Include the Xcode version** in any build-output cache key.
- **Treat DerivedData caching as opt-in + measured**, not default.
- **Keep cached paths tight**; respect the budget so hot caches aren't evicted.
- **Add a version prefix** to keys so you can force-invalidate without renaming everything.

---

**Next:** [Part 14 — Artifacts](part-14-artifacts.md): persisting the outputs (ipa, xcarchive,
xcresult, logs) that caching deliberately doesn't.
