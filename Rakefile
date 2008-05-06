require "rubygems"
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require "rake/gempackagetask"
require 'spec/rake/spectask'

PKG_VERSION = "0.7"
PKG_NAME = "pdf-reader"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

desc "Default Task"
task :default => [ :spec ]

# run all rspecs
desc "Run all rspec files"
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_files = FileList['specs/**/*.rb']
  t.rcov = true
  t.rcov_dir = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + "/rcov"
 # t.rcov_opts = ["--exclude","spec.*\.rb"]
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
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('TODO')
  rdoc.rdoc_files.include('CHANGELOG')
  #rdoc.rdoc_files.include('COPYING')
  #rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << "--inline-source"
end

# a gemspec for packaging this library 
# RSpec files aren't included, as they depend on the PDF files,
# which will make the gem filesize irritatingly large
spec = Gem::Specification.new do |spec|
	spec.name = PKG_NAME
	spec.version = PKG_VERSION
	spec.platform = Gem::Platform::RUBY
	spec.summary = "A library for accessing the content of PDF files"
	spec.files =  Dir.glob("{examples,lib}/**/**/*") +
                      ["Rakefile"]
  
  spec.require_path = "lib"
	spec.has_rdoc = true
	spec.extra_rdoc_files = %w{README TODO CHANGELOG}
	spec.rdoc_options << '--title' << 'PDF::Reader Documentation' <<
	                     '--main'  << 'README' << '-q'
  spec.author = "Peter Jones"
	spec.email = "pjones@pmade.com"
	spec.rubyforge_project = "pdf-reader"
	spec.homepage = "http://software.pmade.com/pdfreader"
	spec.description = "The PDF::Reader library implements a PDF parser conforming as much as possible to the PDF specification from Adobe"
end

# package the library into a gem
desc "Generate a gem for pdf-reader"
Rake::GemPackageTask.new(spec) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end
