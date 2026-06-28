# Part 12 — Static Analysis (SwiftLint, SwiftFormat, Danger)

Static analysis = checks that read your code/PR **without running it** and fail the build when
rules are broken. They enforce consistency and process mechanically, so humans review *logic*, not
brace placement. Real config files are committed: [`.swiftlint.yml`](../../.swiftlint.yml),
[`.swiftformat`](../../.swiftformat), [`Dangerfile`](../../Dangerfile).

## 12.1 The three tools and what each owns

```
 SwiftLint   ── code STYLE + correctness smells   (force-unwraps, long funcs, naming)
 SwiftFormat ── code FORMATTING                    (indentation, spacing, import order)
 Danger      ── PR/PROCESS hygiene                 (tests added? PR size? changelog? assignee?)
```
They're complementary: SwiftLint/SwiftFormat read *source files*; Danger reads the *pull request*
(diff, files changed, metadata).

## 12.2 How a check "fails the build"

Same mechanism as everything in CI: **nonzero exit code**.
```
swiftlint --strict        # any violation → exit 1 → step fails → job fails → ❌ PR check
swiftformat --lint .      # any unformatted file → exit 1 → ❌
bundle exec danger        # any Danger fail() → exit 1 → ❌
```
With **branch protection** making these **required checks** (Part 21), ❌ blocks the merge button.

## 12.3 SwiftLint

**What.** Lints Swift for style + a set of correctness rules. `--strict` turns warnings into
errors (so "just a warning" can't accumulate).

[`.swiftlint.yml`](../../.swiftlint.yml) (committed):
```yaml
disabled_rules:
  - todo                        # we track TODOs elsewhere; don't fail on them
opt_in_rules:                   # high-value rules off by default
  - force_unwrapping
  - empty_count
  - first_where
  - sorted_imports
included: [ App/Sources, App/Tests ]
excluded:  [ "**/.build", "**/DerivedData", "App/Sources/Generated" ]
line_length:
  warning: 120
  error: 200
type_body_length: { warning: 300, error: 500 }
function_body_length: { warning: 60, error: 120 }
identifier_name:
  min_length: 2                 # allow "id", "vm"
```
Run in CI (our `ci.yml`/`lint` lane):
```bash
brew install swiftlint
swiftlint --strict
```

**Line-by-line of choices.** `force_unwrapping` opt-in catches `!` crashes early; `line_length`
warns at 120 but only *fails* at 200 (avoids nitpicking every wrap); `excluded` keeps generated
code out so machine output doesn't fail human rules.

## 12.4 SwiftFormat

**What.** Auto-formats code. In CI you run it in **`--lint`** mode: it doesn't rewrite, it just
**fails if anything isn't already formatted**, forcing the author to run it locally first.

[`.swiftformat`](../../.swiftformat) (committed):
```
--swiftversion 6.0
--indent 4
--maxwidth 120
--importgrouping testable-bottom
--self remove
--commas inline
--exclude .build,DerivedData,App/Sources/Generated
```
CI:
```bash
brew install swiftformat
swiftformat --lint .            # exit 1 if any file would change
```
**Tip:** add a pre-commit hook or `lint:fix` lane (`swiftformat .`) so formatting is fixed before
push — CI just verifies.

## 12.5 Danger — PR automation

**What.** Runs on each PR with access to the **diff and PR metadata**, and posts a comment +
pass/warn/fail. It enforces things linters can't see: "you changed code but added no tests,"
"this PR is huge," "you bumped the version but not the changelog."

[`Dangerfile`](../../Dangerfile) (committed, Ruby):
```ruby
# 1) Big PRs are hard to review.
warn("Big PR (#{git.lines_of_code} lines). Consider splitting.") if git.lines_of_code > 500

# 2) Source changed but no tests touched → likely missing coverage.
has_src   = !git.modified_files.grep(/App\/Sources\//).empty?
has_tests = !(git.modified_files + git.added_files).grep(/App\/Tests\//).empty?
warn("Code changed but no tests were added/updated.") if has_src && !has_tests

# 3) Version bump must update the changelog.
bumped_version = git.modified_files.include?("Configurations/Version.xcconfig")
touched_log    = git.modified_files.include?("CHANGELOG.md")
fail("Version changed without a CHANGELOG.md entry.") if bumped_version && !touched_log

# 4) Don't merge work-in-progress.
fail("PR title contains WIP — not mergeable.") if github.pr_title =~ /\bWIP\b/i

# 5) Every PR needs an assignee (ownership).
warn("PR has no assignee.") if github.pr_json["assignee"].nil?

# 6) Surface SwiftLint results inline on the diff (via plugin).
swiftlint.lint_files inline_mode: true
```
- **`warn`** → yellow, informational, doesn't block.
- **`fail`** → red, **blocks merge** (nonzero exit).
- **`message`/`markdown`** → neutral info (e.g. coverage table).

CI (our `ci.yml` `danger` job):
```yaml
- uses: ruby/setup-ruby@v1
  with: { bundler-cache: true }
- run: bundle exec danger
  env: { DANGER_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
```
It uses the auto `GITHUB_TOKEN` (scoped by `permissions: pull-requests: write`, Part 4) to comment.

## 12.6 SonarQube (optional, larger orgs)
Deeper static analysis (bugs, security hotspots, duplication, maintainability) with historical
trends and a "quality gate" that can fail the build. Heavier to operate; most teams start with
SwiftLint + Danger and add Sonar when they need org-wide metrics/compliance.

## 12.7 Where they sit in the pipeline
```
 checkout ─▶ SwiftFormat --lint ─▶ SwiftLint --strict ─▶ (build/test) ─▶ Danger (PR only)
            └──── cheap, seconds, FIRST (fail fast) ────┘                 └ needs diff + token
```

## 12.8 Common mistakes
- **SwiftLint without `--strict`** → warnings pile up and are ignored.
- **SwiftFormat in write mode on CI** → it "passes" by rewriting on the runner; the repo stays
  unformatted. Use `--lint`.
- **Danger needing secrets on fork PRs** → fork PRs have no token; use `pull_request_target`
  carefully or accept Danger runs only on internal PRs.
- **Linting generated code** → machine output fails human rules; exclude it.
- **Over-strict gates day one** → a red wall of style failures on legacy code. Adopt gradually
  (baseline, then ratchet).

## 12.9 Debugging
- Run locally exactly as CI does: `swiftlint --strict`, `swiftformat --lint .`,
  `bundle exec danger pr <PR-url>` (Danger's local PR mode).
- `swiftlint rules` lists all rules + whether enabled; `swiftlint --fix` auto-fixes the fixable.
- Danger not commenting → check `permissions: pull-requests: write` and `DANGER_GITHUB_API_TOKEN`.

## 12.10 Best practices
- **Cheapest checks first, `--strict`/`--lint` modes** so they truly gate.
- **Auto-fix locally (hook/lane), verify in CI** — don't make humans fix what a tool can.
- **Danger enforces process** (tests, size, changelog, WIP) that no linter can.
- **Exclude generated code; adopt strictness gradually** on legacy codebases.
- **Make them required checks** (Part 21) or they're just suggestions.

---

**Next (Batch 5):** [Part 13 — Caching](part-13-caching.md): make all of this fast by not
re-downloading/rebuilding the same things every run.
