#!/usr/bin/env ruby
# coding: utf-8

# get direct access to PDF objects
#
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

filename = File.dirname(__FILE__) + "/../specs/data/cairo-unicode.pdf"
hash = PDF::Reader::ObjectHash.new(filename)
puts hash[3]
