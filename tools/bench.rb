# coding: utf-8

# a quick script for profiling performance with perftools.
#
# USAGE
#
#     ruby tools/bench.rb
#     evince bench.pdf

$:.unshift "../lib"
require 'pdf-reader'
require 'perftools'

PerfTools::CpuProfiler.start("/tmp/restart_profile") do
  PDF::Reader.open("restart.pdf") do |reader|
    reader.pages.each do |page|
      page.text
    end
  end
end

`pprof.rb --text /tmp/restart_profile > bench.txt`
`pprof.rb --pdf  /tmp/restart_profile > bench.pdf`
