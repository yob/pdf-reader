# coding: utf-8

# a script for measuring text extraction performance

# TO BENCHMARK: ruby tools/bench.rb <runs>
# TO PROFILE:   ruby tools/bench.rb perftools
#         OR:   ruby-prof tools/bench.rb <runs>
# FOR OBJECT ALLOCATION STATS: ruby tools/bench.rb memprof
# TO COUNT GC RUNS: ruby tools/bench.rb gc

$project_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'rubygems' # for Ruby 1.8
$:.unshift "#{$project_root}/lib"
require 'pdf/reader'

# Extract all the text from a large PDF

def extract_text
  PDF::Reader.open("#{$project_root}/spec/data/no_text_spaces.pdf") do |reader|
    reader.pages.each do |page|
      page.text
    end
  end
end

case ARGV[0]
when "memprof"
  # Measure object allocation with memprof
  require 'memprof'
  GC.disable
  Memprof.track { extract_text }

when "perftools"
  # Profile with perftools.rb
  # (The best thing about perftools.rb is that it shows you time spent on
  #   garbage collection)
  require 'perftools'
  PerfTools::CpuProfiler.start("/tmp/perftools_data") do
    extract_text
  end
  `pprof.rb --text /tmp/perftools_data > #{$project_root}/tools/profiles/perftools.txt`
  `pprof.rb --pdf /tmp/perftools_data > #{$project_root}/tools/profiles/perftools.pdf`

when "gc"
  before = GC.count
  extract_text
  puts "GC ran #{GC.count - before} times"

when "allocations"
  GC.disable
  before = ObjectSpace.count_objects
  extract_text
  after = ObjectSpace.count_objects
  after.each do |key, val|
    puts "#{key}: #{val - before[key]}"
  end
  GC.start

else
  # Benchmark
  # Average the results over multiple runs
  # Throw out the best and worst results, and average what remains
  # With 10 runs, the results seem to fluctuate by as much as 6-7%
  # I'd like that to be 1-2%, but that requires a VERY high number of runs

  runs  = (ARGV[0] || 10).to_i
  times = []

  runs.times do
    start = Time.new
    extract_text
    times << (Time.new - start)
    sleep(0.1) # results seem more consistent this way
  end

  times.sort!
  times = times.drop(runs / 5).take(runs - (runs * 2 / 3))
  average = times.reduce(0,&:+).to_f / times.size
  puts "#{"%0.3f" % average} seconds"
end
