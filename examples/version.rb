#!/usr/bin/env ruby
# coding: utf-8

# Determine the PDF version of a file

require 'rubygems'
require 'pdf/reader'

class VersionReceiver
  attr_accessor :version

  def initialize
    @version = nil
  end

  # Called when document parsing starts
  def pdf_version(arg = nil)
    @version = arg
  end

end

receiver = VersionReceiver.new
pdf = PDF::Reader.file(ARGV.shift, receiver)
puts receiver.version
