# Driver to run a bunch of profiling scripts in parallel,
#   leaving all the results in tools/profiles
# Assumes "ruby" is Ruby 1.9, and "ruby1.8" is Ruby 1.8.7
# Also assumes that all needed gems are installed
# This script itself should be run under Ruby 1.9

require 'fileutils'

project_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
dir = "#{project_root}/tools/profiles"
FileUtils.mkdir(dir) unless File.exist?(dir)

pids = []
pids << fork { `ruby-prof #{project_root}/tools/bench.rb 1 --file=#{dir}/rubyprof.txt` }
pids << fork { `ruby-prof #{project_root}/tools/bench.rb 1 --file=#{dir}/rubyprof-graph.htm --printer=graph_html` }
pids << fork { `ruby-prof #{project_root}/tools/bench.rb 1 --file=#{dir}/rubyprof-stack.htm --printer=call_stack` }
pids << fork { `ruby1.8 #{project_root}/tools/bench.rb memprof > #{dir}/memprof.txt` }
pids << fork { `ruby #{project_root}/tools/bench.rb perftools` }

pids.each { |pid| Process.wait(pid) }
