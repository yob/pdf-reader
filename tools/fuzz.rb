#!/usr/bin/env ruby
###################################################
# ----------------------------------------------- #
# Fuzz pdf-reader Ruby gem with mutated PDF files #
# ----------------------------------------------- #
#                                                 #
# Each test case is written to 'fuzz.pdf' in the  #
# current working directory.                      #
#                                                 #
# Crashes and the associated backtrace are saved  #
# in the 'crashes' directory in the current       #
# working directory.                              #
#                                                 #
###################################################
# ~ bcoles

require 'date'
require 'pdf-reader'
require 'colorize'
require 'fileutils'
require 'timeout'
require 'securerandom'

VERBOSE = false
OUTPUT_DIR = "#{Dir.pwd}/crashes".freeze

#
# Show usage
#
def usage
  puts 'Usage: ./fuzz.rb <FILE1> [FILE2] [FILE3] [...]'
  puts 'Example: ./tools/fuzz.rb spec/data/**.pdf'
  exit 1
end

#
# Print status message
#
# @param [String] msg message to print
#
def print_status(msg = '')
  puts '[*] '.blue + msg if VERBOSE
end

#
# Print progress messages
#
# @param [String] msg message to print
#
def print_good(msg = '')
  puts '[+] '.green + msg if VERBOSE
end

#
# Print error message
#
# @param [String] msg message to print
#
def print_error(msg = '')
  puts '[-] '.red + msg
end

#
# Setup environment
#
def setup
  FileUtils.mkdir_p OUTPUT_DIR unless File.directory? OUTPUT_DIR
rescue => e
  print_error "Could not create output directory '#{OUTPUT_DIR}': #{e}"
  exit 1
end

#
# Generate a mutated PDF file with a single mitated byte
#
# @param [Path] f path to PDF file
#
def mutate_byte(f)
  data = IO.binread f
  position = SecureRandom.random_number data.size
  new_byte = SecureRandom.random_number 256
  new_data = data.dup.tap { |s| s.setbyte(position, new_byte) }

  File.open(@fuzz_outfile, 'w') do |file|
    file.write new_data
  end
end

#
# Generate a mutated PDF file with multiple mutated bytes
#
# @param [Path] f path to PDF file
#
def mutate_bytes(f)
  data = IO.binread f
  fuzz_factor = 200
  num_writes = rand((data.size / fuzz_factor.to_f).ceil) + 1

  new_data = data.dup
  num_writes.times do
    position = SecureRandom.random_number data.size
    new_byte = SecureRandom.random_number 256
    new_data.tap { |stream| stream.setbyte position, new_byte }
  end

  File.open(@fuzz_outfile, 'w') do |file|
    file.write new_data
  end
end

#
# Generate a mutated PDF file with all integers replaced by '-1'
#
# @param [Path] f path to PDF file
#
def clobber_integers(f)
  data = IO.binread f
  new_data = data.dup.gsub(/\d/, '-1')

  File.open(@fuzz_outfile, 'w') do |file|
    file.write new_data
  end
end

#
# Generate a mutated PDF file with all strings 3 characters or longer
# replaced with 2000 'A' characters
#
# @param [Path] f path to PDF file
#
def clobber_strings(f)
  data = IO.binread f
  new_data = data.dup.gsub(/[a-zA-Z]{3,}/, 'A' * 2000)

  File.open(@fuzz_outfile, 'w') do |file|
    file.write new_data
  end
end

#
# Read a PDF file
#
# @param [String] f path to PDF file
#
def read(f)
  print_status "Processing '#{f}'"
  begin
    reader = PDF::Reader.new f
  rescue PDF::Reader::MalformedPDFError
    print_status "Could not parse PDF '#{f}': PDF is malformed"
    return
  rescue PDF::Reader::UnsupportedFeatureError
    print_status "Could not parse PDF '#{f}': PDF::Reader::UnsupportedFeatureError"
    return
  end
  print_good 'Processing complete'

  print_status "Parsing '#{f}'"
  begin
    parse reader
  rescue PDF::Reader::UnsupportedFeatureError
    print_status "Could not parse PDF '#{f}': PDF::Reader::UnsupportedFeatureError"
    return
  rescue PDF::Reader::MalformedPDFError
    print_status "Could not parse PDF '#{f}': PDF is malformed"
    return
  end
  print_good 'Parsing complete'
end

#
# Parse PDF
#
def parse(reader)
  print_status "Version: #{reader.pdf_version}"
  print_status "Info: #{reader.info}"
  print_status "Metadata: #{reader.metadata}"
  print_status "Objects: #{reader.objects}"
  print_status "Pages: #{reader.page_count}"

  print_status 'Parsing PDF contents...'
  contents = ''
  reader.pages.each do |page|
    contents << page.fonts.to_s
    contents << page.text #.force_encoding('utf-8')
    contents << page.raw_content.force_encoding('utf-8')
  end
  # puts contents if VERBOSE
end

#
# Show summary of crashes
#
def summary
  puts
  puts "Complete! Crashes saved to '#{OUTPUT_DIR}'"
  puts
  puts `/usr/bin/head -n1 #{OUTPUT_DIR}/*.trace` if File.exist? '/usr/bin/head'
end

#
# Report error message to STDOUT
# and save fuzz test case and backtrace to OUTPUT_DIR
#
def report_crash(e)
  puts " - #{e.message}"
  puts e.backtrace.first
  fname = "#{DateTime.now.strftime('%Y%m%d%H%M%S%N')}_crash_#{rand(1000)}"
  FileUtils.mv @fuzz_outfile, "#{OUTPUT_DIR}/#{fname}.pdf"
  File.open("#{OUTPUT_DIR}/#{fname}.pdf.trace", 'w') do |file|
    file.write "#{e.message}\n#{e.backtrace.join "\n"}"
  end
end

#
# Test pdf-reader with the mutated file
#
def test
  Timeout.timeout(@timeout) do
    read @fuzz_outfile
  end
rescue SystemStackError => e
  report_crash e
rescue Timeout::Error => e
  report_crash e
rescue SyntaxError => e
  report_crash e
rescue => e
  raise e unless e.backtrace.join("\n") =~ %r{gems/pdf-reader}
  report_crash e
end

#
# Generate random byte mutations and run test
#
# @param [String] f path to PDF file
#
def fuzz_bytes(f)
  iterations = 1000
  1.upto(iterations) do |i|
    print "\r#{(i * 100) / iterations} % (#{i} / #{iterations})"
    mutate_bytes f
    test
  end
end

#
# Generate integer mutations and run tests
#
# @param [String] f path to PDF file
#
def fuzz_integers(f)
  clobber_integers f
  test
end

#
# Generate string mutations and run tests
#
# @param [String] f path to PDF file
#
def fuzz_strings(f)
  clobber_strings f
  test
end

puts '-' * 60
puts '% Fuzzer for pdf-reader Ruby gem'
puts '-' * 60
puts

usage if ARGV[0].nil?

setup

@timeout = 15
@fuzz_outfile = 'fuzz.pdf'

trap 'SIGINT' do
  puts
  puts 'Caught interrupt. Exiting...'
  summary
  exit 130
end

ARGV.each do |f|
  unless File.exist? f
    print_error "Could not find file '#{f}'"
    next
  end

  fuzz_integers f
  fuzz_strings f
  fuzz_bytes f

  puts '-' * 60
end

summary

