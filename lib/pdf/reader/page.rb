# coding: utf-8

module PDF
  class Reader

    # high level representation of a single PDF page. Ties together the various
    # low level classes in PDF::Reader and provides access to the various
    # components of the page (text, images, fonts, etc) in convenient formats.
    #
    # If you require access to the raw PDF objects for this page, you can access
    # the Page dictionary via the page_object accessor. You will need to use the
    # objects accessor to help walk the page dictionary in any useful way.
    #
    class Page

      # lowlevel hash-like access to all objects in the underlying PDF
      attr_reader :objects

      # the raw PDF object that defines this page
      attr_reader :page_object

      # creates a new page wrapper.
      #
      # * objects - an ObjectHash instance that wraps a PDF file
      # * pagenum - an int specifying the page number to expose. 1 indexed.
      #
      def initialize(objects, pagenum)
        @objects, @pagenum = objects, pagenum
        @page_object = objects.deref(objects.page_references[pagenum - 1])

        unless @page_object.is_a?(::Hash)
          raise ArgumentError, "invalid page: #{pagenum}"
        end
      end

      # return the number of this page within the full document
      #
      def number
        @pagenum
      end

      # return a friendly string representation of this page
      #
      def inspect
        "<PDF::Reader::Page page: #{@pagenum}>"
      end

      # Returns the attributes that accompany this page. Includes
      # attributes inherited from parents.
      #
      def attributes
        hash = {}
        page_with_ancestors.reverse.each do |obj|
          hash.merge!(@objects.deref(obj))
        end
        hash
      end

      # Returns the resources that accompany this page. Includes
      # resources inherited from parents.
      #
      def resources
        @resources ||= @objects.deref(attributes[:Resources]) || {}
      end

      # return a hash of fonts used on this page.
      #
      # The keys are the font labels used within the page content stream.
      #
      # The values are a PDF::Reader::Font instances that provide access
      # to most available metrics for each font.
      #
      def fonts
        raw_fonts = objects.deref(resources[:Font] || {})
        ::Hash[raw_fonts.map { |label, font|
          [label, PDF::Reader::Font.new(objects, objects.deref(font))]
        }]
      end

      # returns the plain text content of this page encoded as UTF-8. Any
      # characters that can't be translated will be returned as a ▯
      #
      def text
        text_receiver = PageTextReceiver.new(fonts)
        walk(text_receiver)
        text_receiver.content
      end
      alias :to_s :text

      # processes the raw content stream for this page in sequential order and
      # passes callbacks to the receiver objects.
      #
      # This is mostly low level and you can probably ignore it unless you need
      # access to soemthing like the raw encoded text. For an example of how
      # this can be used as a basis for higher level functionality, see the
      # text() method
      #
      def walk(*receivers)
        callback(receivers, :page=, [self])
        content_stream(receivers, raw_content)
      end

      # returns the raw content stream for this page. This is plumbing, nothing to
      # see here unless you're a PDF nerd like me.
      #
      def raw_content
        contents = objects.deref(@page_object[:Contents])
        [contents].flatten.compact.map { |obj|
          objects.deref(obj)
        }.map { |obj|
          obj.unfiltered_data
        }.join
      end

      private

      def root
        root ||= objects.deref(@objects.trailer[:Root])
      end

      def xobjects
        resources[:XObject] || {}
      end

      def content_stream(receivers, instructions)
        buffer       = Buffer.new(StringIO.new(instructions), :content_stream => true)
        parser       = Parser.new(buffer, @objects)
        params       = []

        while (token = parser.parse_token(PagesStrategy::OPERATORS))
          if token.kind_of?(Token) and PagesStrategy::OPERATORS.has_key?(token)
            callback(receivers, PagesStrategy::OPERATORS[token], params)
            params.clear
          else
            params << token
          end
        end
      rescue EOFError => e
        raise MalformedPDFError, "End Of File while processing a content stream"
      end

      # calls the name callback method on the receiver class with params as the arguments
      #
      def callback (receivers, name, params=[])
        receivers.each do |receiver|
          receiver.send(name, *params) if receiver.respond_to?(name)
        end
      end

      def page_with_ancestors(obj = nil)
        obj = objects.deref(obj)
        if obj.nil?
          [@page_object] + page_with_ancestors(@page_object[:Parent])
        elsif obj[:Parent]
          [select_inheritable(obj)] + page_with_ancestors(obj[:Parent])
        else
          [select_inheritable(obj)]
        end
      end

      # select the elements from a Pages dictionary that can be inherited by
      # child Page dictionaries.
      #
      def select_inheritable(obj)
        ::Hash[obj.select { |key, value|
          [:Resources, :MediaBox, :CropBox, :Rotate, :Parent].include?(key)
        }]
      end

    end
  end
end
