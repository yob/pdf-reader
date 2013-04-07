# RSpec files aren't included, as they depend on the PDF files,
# which will make the gem filesize irritatingly large
Gem::Specification.new do |spec|
  spec.name = "pdf-reader"
  spec.version = "1.3.3"
  spec.summary = "A library for accessing the content of PDF files"
  spec.description = "The PDF::Reader library implements a PDF parser conforming as much as possible to the PDF specification from Adobe"
  spec.files =  Dir.glob("{examples,lib}/**/**/*") + ["Rakefile"]
  spec.executables << "pdf_object"
  spec.executables << "pdf_text"
  spec.executables << "pdf_list_callbacks"
  spec.executables << "pdf_callbacks"
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README.rdoc TODO CHANGELOG MIT-LICENSE }
  spec.rdoc_options << '--title' << 'PDF::Reader Documentation' <<
                       '--main'  << 'README.rdoc' << '-q'
  spec.authors = ["James Healy"]
  spec.email   = ["jimmy@deefa.com"]
  spec.homepage = "http://github.com/yob/pdf-reader"
  spec.required_ruby_version = ">=1.8.7"

  spec.add_development_dependency("rake")
  spec.add_development_dependency("rspec", "~>2.3")
  spec.add_development_dependency("ZenTest", "~>4.4.2")
  spec.add_development_dependency("cane", "~>2.2.3")
  spec.add_development_dependency("morecane")
  spec.add_development_dependency("ir_b")
  spec.add_development_dependency("rdoc")

  spec.add_dependency('Ascii85', '~> 1.0.0')
  spec.add_dependency('ruby-rc4')
  spec.add_dependency('hashery', '~> 2.0')
  spec.add_dependency('ttfunk')
  spec.add_dependency('afm', '~> 0.2.0')

  spec.post_install_message = <<END_DESC

  ********************************************

  v1.0.0 of PDF::Reader introduced a new page-based API. There are extensive
  examples showing how to use it in the README and examples directory.

  For detailed documentation, check the rdocs for the PDF::Reader,
  PDF::Reader::Page and PDF::Reader::ObjectHash classes.

  The old API is marked as deprecated but will continue to work with no
  visible warnings for now.

  ********************************************

END_DESC
end
