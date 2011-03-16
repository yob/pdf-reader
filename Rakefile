require "rubygems"
require "bundler"
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'
require 'roodi'
require 'roodi_task'

desc "Default Task"
task :default => [ :spec ]

# run all rspecs
desc "Run all rspec files"
RSpec::Core::RakeTask.new("spec") do |t|
  t.rspec_opts  = ["--color", "--format progress"]
  # turn this off for now. I'd like to leave it on, but thor throws
  # a large amount of noise to my console if I do
  #t.ruby_opts = "-w"
end

RoodiTask.new 'roodi', ['lib/**/*.rb']
