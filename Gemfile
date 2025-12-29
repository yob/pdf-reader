source "https://gem.coop"

gemspec

# We require sorbet here rather than in the gemspec so we can avoid loading it in CI
# for rubies < 2.7
gem "sorbet", "0.6.12872"
gem "tapioca", "0.17.10", require: false

# For exporting RBS type annotations to a sorbet compatible RBI file
gem "spoom"

# For exporting inline RBS type annotations to an external RBS file
gem "rbs-inline", require: false

# Required by yard. Part of stdlib in older rubies, but on modern rubies it's a gem
gem "webrick"
