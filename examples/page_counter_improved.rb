#!/usr/bin/env ruby
# coding: utf-8

# Improved Page Counter
#
# A simple app to display the number of pages in a PDF File.
#

  require 'rubygems'
  require 'pdf/reader'

  class PageReceiver
    attr_accessor :pages

    # Called when page parsing ends
    def page_count(arg)
      @pages = arg
    end
  end

  receiver = PageReceiver.new
  pdf = PDF::Reader.file("somefile.pdf", receiver, :pages => false)
  puts "#{receiver.pages} pages"
