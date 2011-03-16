# coding: utf-8

# some helper methods available to all specs
module PreflightSpecHelper

  def pdf_spec_file(base)
    base_path = File.expand_path(File.dirname(__FILE__) + "/../pdfs")
    filename  = File.join(base_path, "#{base}.pdf")
    if File.file?(filename)
      return filename
    else
      raise ArgumentError, "#{filename} not found"
    end
  end

  # returns a hash suitable for passing to the constructor for each strategy
  # class.
  def strategy_args(gem_name)
    base_path = File.expand_path(File.dirname(__FILE__) + "/../gems")
    {
      :filename      => "lint-1.0.gem",
      :data_path     => File.join(base_path, gem_name, "data"),
      :metadata_path => File.join(base_path, gem_name, "metadata")
    }
  end
end
