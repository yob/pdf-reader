require "rubygems"
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require "rake/gempackagetask"
require 'spec/rake/spectask'
require 'roodi'
require 'roodi_task'

desc "Default Task"
task :default => [ :spec ]

# run all rspecs
desc "Run all rspec files"
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_files =  FileList['specs/**/*.rb']
  t.spec_opts  = ["--color", "--format progress"]
  t.rcov       =  false
  t.ruby_opts  << "-w"
end

# generate specdocs
desc "Generate Specdocs"
Spec::Rake::SpecTask.new("specdocs") do |t|
  t.spec_files = FileList['specs/**/*.rb']
  t.spec_opts = ["--format", "rdoc"]
  t.out = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/specdoc.rd'
end

# generate failing spec report
desc "Generate failing spec report"
Spec::Rake::SpecTask.new("spec_report") do |t|
  t.spec_files = FileList['specs/**/*.rb']
  t.spec_opts = ["--format", "html", "--diff"]
  t.out = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/spec_report.html'
  t.fail_on_error = false
end

# Genereate the RDoc documentation
desc "Create documentation"
Rake::RDocTask.new("doc") do |rdoc|
  rdoc.title = "pdf-reader"
  rdoc.rdoc_dir = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('TODO')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('MIT-LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << "--inline-source"
end

RoodiTask.new 'roodi', ['lib/**/*.rb']
