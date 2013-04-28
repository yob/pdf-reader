= Release Notes

Marron provides low level parsing of PDF files in pure ruby. PDF objects are
deserialised into ruby and made available via simple APIs. 

No attempt is made to interpret the PDF object meaning, render pages or extract
text. Consider this library the foundation for higher level functionality. You
might find the pdf-reader gem useful for page based acess to the content of
PDFs.

= Installation

The recommended installation method is via Rubygems.

  gem install marron

= Usage

Begin by creating a Marron::ObjectHash instance that points to a PDF file. This
object will provide access to the raw PDF objects via a hash-like API

    objects = Marron::ObjectHash.new("somefile.pdf")
    puts objects[1]
    => 3469

Marron::ObjectHash.new accepts an IO stream or a filename. Here's an example with
an IO stream:

    require 'open-uri'

    io      = open('http://example.com/somefile.pdf')
    objects = Marron::ObjectHash.new(io)
    puts objects[1]

If you open a PDF with File#open or IO#open, I strongly recommend using "rb"
mode to ensure the file isn't mangled by ruby being 'helpful'. This is
particularly important on windows and MRI >= 1.9.2.

    File.open("somefile.pdf", "rb") do |io|
      objects = Marron::ObjectHash.new(io)
      puts objects[1]
    end

= Exceptions

There are two key exceptions that you will need to watch out for when processing a
PDF file:

MalformedPDFError - The PDF appears to be corrupt in some way. If you believe the
file should be valid, or that a corrupt file didn't raise an exception, please
forward a copy of the file to the maintainers (preferably via the google group)
and we will attempt to improve the code.

UnsupportedFeatureError - The PDF uses a feature that Marron doesn't currently
support. Again, we welcome submissions of PDF files that exhibit these features to help
us with future code improvements.

MalformedPDFError has some subclasses if you want to detect finer grained issues. If you
don't, 'rescue MalformedPDFError' will catch all the subclassed errors as well.

Any other exceptions should be considered bugs in marron (please report it!).

= Maintainers

- James Healy <mailto:jimmy@deefa.com>

= Licensing

This library is distributed under the terms of the MIT License. See the included file for
more detail.

= Mailing List

Any questions or feedback should be sent to the PDF::Reader google group. It's
better that any answers be available for others instead of hiding in someone's
inbox.

http://groups.google.com/group/pdf-reader

= Examples

The easiest way to explain how this works in practice is to show some examples.
Check out the examples/ directory for a few files.

= Resources

- PDF::Reader Code Repository: http://github.com/yob/pdf-reader
- PDF Specification: http://www.adobe.com/devnet/pdf/pdf_reference.html
- PDF Tutorial Slide Presentations: http://home.comcast.net/~jk05/presentations/PDFTutorials.html
- Developing with PDF (book): http://shop.oreilly.com/product/0636920025269.do
