# Danger — PR hygiene rules. Run in CI as: bundle exec danger
# warn() = advisory (yellow), fail() = blocks merge (red).
# Teaching reference: docs/cicd/part-12-static-analysis.md

# 1) Big PRs are hard to review.
warn("Big PR (#{git.lines_of_code} lines changed). Consider splitting it.") if git.lines_of_code > 500

# 2) Source changed but no tests touched → probably missing coverage.
has_src   = !git.modified_files.grep(%r{App/Sources/}).empty?
has_tests = !(git.modified_files + git.added_files).grep(%r{App/Tests/}).empty?
warn("Source changed but no tests were added/updated.") if has_src && !has_tests

# 3) A version bump must update the changelog.
bumped_version = git.modified_files.include?("Configurations/Version.xcconfig")
touched_log    = git.modified_files.include?("CHANGELOG.md")
fail("Version bumped without a CHANGELOG.md entry.") if bumped_version && !touched_log

# 4) Don't merge work-in-progress.
fail("PR title contains WIP — not mergeable.") if github.pr_title =~ /\bWIP\b/i

# 5) Ownership: every PR should have an assignee.
warn("PR has no assignee.") if github.pr_json["assignee"].nil?

# 6) Encourage a description.
warn("PR body is empty — add context for reviewers.") if github.pr_body.to_s.strip.empty?
