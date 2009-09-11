#!/usr/bin/env ruby
# coding: utf-8

# A simple app to count the number of pages in a PDF File.

require 'rubygems'
require 'pdf/reader'

class PageReceiver
  attr_accessor :counter

  def initialize
    @counter = 0
  end

  # Called when page parsing ends
  def end_page
    @counter += 1
  end
end

receiver = PageReceiver.new
pdf = PDF::Reader.file("somefile.pdf", receiver)
puts "#{receiver.counter} pages"
