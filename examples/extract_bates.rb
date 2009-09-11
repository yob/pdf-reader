#!/usr/bin/env ruby
# coding: utf-8

# A sample script that attempts to extract bates numbers from a PDF file.
# Bates numbers are often used to markup documents being used in legal
# cases. For more info, see http://en.wikipedia.org/wiki/Bates_numbering
#
# Acrobat 9 introduced a markup syntax that directly specifies the bates
# number for each page. For earlier versions, the easiest way to find
# the number is to look for words that match a pattern.
#
# This example attempts to extract numbers using the Acrobat 9 syntax.
# As a fall back, you can provide a regular expression that will be
# used to look for words that look like the numbers you expect in the
# page content.

require 'rubygems'
require 'pdf/reader'

class BatesReceiver

  def initialize(regexp = nil)
    @numbers = []
    @backup  = []
    @regexp  = regexp
  end 

  def numbers
    @numbers.size > 0 ? @numbers : @backup
  end

  # Called when page parsing starts
  def begin_marked_content(*args)
    return unless args.size >= 2
    return unless args.first == :Artifact
    return unless args[1][:Subtype] == :BatesN

    @numbers << args[1][:Contents]
  end
  alias :begin_marked_content_with_pl :begin_marked_content

  # record text that is drawn on the page
  def show_text(string, *params)
    return if @regexp.nil?

    string.scan(@regexp).each { |m| @backup << m }
  end

  # there's a few text callbacks, so make sure we process them all
  alias :super_show_text :show_text
  alias :move_to_next_line_and_show_text :show_text
  alias :set_spacing_next_line_show_text :show_text

  # this final text callback takes slightly different arguments
  def show_text_with_positioning(*params)
    params = params.first
    params.each { |str| show_text(str) if str.kind_of?(String)}
  end
end

receiver = BatesReceiver.new(/CC.+/)
PDF::Reader.file("bates.pdf", receiver)
puts receiver.numbers.inspect
