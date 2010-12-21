# RSpec files aren't included, as they depend on the PDF files,
# which will make the gem filesize irritatingly large
Gem::Specification.new do |spec|
  spec.name = "pdf-reader"
  spec.version = "0.9.1"
  spec.summary = "A library for accessing the content of PDF files"
  spec.description = "The PDF::Reader library implements a PDF parser conforming as much as possible to the PDF specification from Adobe"
  spec.files =  Dir.glob("{examples,lib}/**/**/*") + ["Rakefile"]
  spec.executables << "pdf_object"
  spec.executables << "pdf_text"
  spec.executables << "pdf_list_callbacks"
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README.rdoc TODO CHANGELOG MIT-LICENSE }
  spec.rdoc_options << '--title' << 'PDF::Reader Documentation' <<
                       '--main'  << 'README.rdoc' << '-q'
  spec.authors = ["James Healy"]
  spec.email   = ["jimmy@deefa.com"]
  spec.homepage = "http://github.com/yob/pdf-reader"
  spec.required_ruby_version = ">=1.8.7"

  spec.add_development_dependency("rake")
  spec.add_development_dependency("roodi")
  spec.add_development_dependency("rspec", "~>2.1")

  spec.add_dependency('Ascii85', '>=0.9')
end
