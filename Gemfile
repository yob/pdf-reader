source "https://rubygems.org"

gemspec

# We require sorbet here rather than in the gemspec so we can avoid loading it in CI
# for rubies < 2.7
gem "sorbet", "0.5.11751"
gem "tapioca", "0.11.6", require: false
gem 'parlour'

# Required by yard. Part of stdlib in older rubies, but on modern rubies it's a gem
gem "webrick"
