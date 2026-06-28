# Ruby tooling for the iOS pipeline. Pinned via Gemfile.lock for reproducible CI.
# Always invoke as `bundle exec fastlane <lane>` so the locked version is used.
# Teaching reference: docs/cicd/part-08-fastlane.md

source "https://rubygems.org"

gem "fastlane"
gem "xcpretty"          # optional log formatter (xcbeautify is installed via brew on CI)

# Danger for PR automation (docs/cicd/part-12 + part-21)
gem "danger"

# Load fastlane plugins declared in fastlane/Pluginfile, if present.
plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
