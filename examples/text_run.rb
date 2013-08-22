#!/usr/bin/env ruby
# coding: utf-8

# Extract all text runs from a single PDF

require 'rubygems'
require 'pdf/reader'
require_relative '../lib/pdf/reader/page_text_receiver'

filename = File.expand_path(File.dirname(__FILE__)) + "/../spec/data/cairo-unicode.pdf"

class Receiver

  include PDF::Reader::ReceivesTextRuns

  def new_text_run(text_run)
    p text_run
  end

end

PDF::Reader.open(filename) do |reader|
  receiver = Receiver.new
  reader.pages.each do |page|
    page.walk receiver
  end
end
