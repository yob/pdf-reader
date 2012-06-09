# coding: utf-8

# a quick script for profiling performance with perftools.
#
# USAGE
#
#     ruby tools/bench.rb
#     evince bench.pdf

#$:.unshift "../lib"
require 'pdf/reader'
#require 'perftools'

PDF::Reader::NewParser

#PerfTools::CpuProfiler.start("/tmp/bench.tmp") do
  PDF::Reader.open("restart.pdf") do |reader|
    #reader.pages.each do |page|
      reader.page(5).text
    #end
  end
#end

#`pprof.rb --text /tmp/restart_profile > bench.txt`
#`pprof.rb --pdf  /tmp/restart_profile > bench.pdf`
