#!/usr/bin/env ruby

# coding: utf-8
# Extract metadata only

require 'rubygems'
require 'pdf/reader'

class MetaDataReceiver
  attr_accessor :regular
  attr_accessor :xml

  def metadata(data)
    @regular = data
  end

  def metadata_xml(data)
    @xml = data
  end
end

receiver = MetaDataReceiver.new
pdf = PDF::Reader.file(ARGV.shift, receiver, :pages => false, :metadata => true)
puts receiver.regular.inspect
puts receiver.xml.inspect
