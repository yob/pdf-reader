require 'bundler/inline'

gemfile do
  source "https://rubygems.org"

  gem "benchmark-memory"
  gem "pdf-reader"
end

require 'benchmark/memory'
require 'pdf-reader'

# Extract text from a variety of PDF files and record how many objects are allocated
#
# USAGE: ruby -I lib scripts/benchmark_allocations.rb

def spec_file_path(name)
  File.join(__dir__, "../spec/data/#{name}.pdf")
end

def parse_file(name)
  puts spec_file_path(name)
  PDF::Reader.open(spec_file_path(name)) do |pdf|
    pdf.pages.map(&:text)
  end
end

Benchmark.memory do |x|
  x.report("cairo-unicode") { parse_file("cairo-unicode") }
  x.report("type1-arial") { parse_file("type1-arial") }
  x.report("truetype-arial") { parse_file("truetype-arial") }
  x.report("ascii85_filter") { parse_file("ascii85_filter") }
  x.report("prince1") { parse_file("prince1") }
  x.report("pdflatex") { parse_file("pdflatex") }
  x.compare!
end
