#!/usr/bin/env ruby
#
# A test script to test loading and parsing a PDF file
#

require 'pdf-reader'
require 'colorize'

$QUIET = false

#
# Usage
#
def usage
  print_status './read-pdf.rb <FILE>'
  exit 1
end

#
# Print status message
#
# @param [String] msg message to print
#
def print_status(msg = '')
  puts '[*] '.blue + msg unless $QUIET
end

#
# Print progress messages
#
# @param [String] msg message to print
#
def print_good(msg = '')
  puts '[+] '.green + msg unless $QUIET
end

#
# Print error message
#
# @param [String] msg message to print
#
def print_error(msg = '')
  puts '[-] '.red + msg unless $QUIET
end

#
# Read a PDF file
#
# @param [File] file PDF file
#
def read doc
  print_status "Processing '#{doc}'"
  begin
    reader = PDF::Reader.new doc
  rescue PDF::Reader::MalformedPDFError
    print_error "Could not parse PDF '#{doc}': PDF is malformed"
    exit 1
  rescue PDF::Reader::UnsupportedFeatureError 
    print_error "Could not parse PDF '#{doc}': PDF::Reader::UnsupportedFeatureError"
    exit 1
  end
  print_good 'Processing complete'

  print_status "Parsing '#{doc}'"
  begin
    parse reader
  rescue PDF::Reader::UnsupportedFeatureError
    print_error "Could not parse PDF '#{doc}': PDF::Reader::UnsupportedFeatureError"
    exit 1
  rescue PDF::Reader::MalformedPDFError => e
    print_error "Could not parse PDF '#{doc}': PDF is malformed"
    exit 1
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
    contents << page.text.force_encoding('utf-8')
    contents << page.raw_content.force_encoding('utf-8')
  end
  #puts contents unless $QUIET
end

doc = ARGV[0]
usage if doc.nil?

if File.exist? doc
  read doc
  exit 0
else
  print_error "Could not find file '#{doc}'"
  exit 1
end
