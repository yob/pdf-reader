# typed: false
# coding: utf-8

# some helper methods available to all specs
module ReaderSpecHelper

  def pdf_spec_file(base)
    base_path = File.expand_path(File.dirname(__FILE__) + "/../data")
    valid_filename    = File.join(base_path, "#{base}.pdf")
    invalid_filename  = File.join(base_path, "invalid", "#{base}.pdf")
    if File.file?(valid_filename)
      return valid_filename
    elsif File.file?(invalid_filename)
      return invalid_filename
    else
      raise ArgumentError, "#{valid_filename} not found"
    end
  end

  # a safe method for opening a file and loading the contents as
  # a binary string.
  #
  def binread(filename)
    if File.respond_to?(:binread)
      File.binread(filename)
    else
      File.open(filename, "rb") { |f| f.read }
    end
  end

end
