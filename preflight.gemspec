Gem::Specification.new do |s|
  s.name              = "preflight"
  s.version           = "0.1.1"
  s.summary           = "Check PDF files conform to various standards"
  s.description       = "Provides a programatic way to check a PDF file conforms to standards like PDF-X/1a"
  s.author            = "James Healy"
  s.email             = ["james@yob.id.au"]
  s.homepage          = "http://github.com/yob/pdf-preflight"
  s.has_rdoc          = true
  s.rdoc_options      << "--title" << "PDF::Preflight" << "--line-numbers"
  s.files             = Dir.glob("lib/**/*") + Dir.glob("bin/*") + ["README.rdoc", "CHANGELOG"]
  s.executables       << "is_pdfx_1a"
  s.required_rubygems_version = ">=1.3.2"

  s.add_dependency("pdf-reader", "~>0.10.0")
  s.add_dependency("ttfunk", "~>1.0.1")

  s.add_development_dependency("rake")
  s.add_development_dependency("roodi")
  s.add_development_dependency("rspec", "~>2.0")
end
