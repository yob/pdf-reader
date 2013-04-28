# RSpec files aren't included, as they depend on the PDF files,
# which will make the gem filesize irritatingly large
Gem::Specification.new do |spec|
  spec.name = "marron"
  spec.version = "1.0.0"
  spec.summary = "A low level for parsing and reading PDF files"
  spec.description = "Marron implements a PDF parser conforming as much as possible to the PDF specification from Adobe"
  spec.files =  Dir.glob("{examples,lib}/**/**/*") + ["Rakefile"]
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README.rdoc TODO CHANGELOG MIT-LICENSE }
  spec.rdoc_options << '--title' << 'Marron Documentation' <<
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
end
