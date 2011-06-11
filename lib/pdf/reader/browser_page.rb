# coding: utf-8

module PDF
  class Reader
    class BrowserPage
      def initialize(ohash, pagenum)
        @ohash, @pagenum = ohash, pagenum
        @page_obj = get_page_obj(pagenum)
      end

      def fonts
        raw_fonts = resources[:Font] || {}
        ::Hash[raw_fonts.map { |label, font|
          [label, PDF::Reader::Font.new(ohash, ohash.object(font))]
        }]
      end

      def xobjects
        resources[:XObject] || {}
      end

      def text
        text_receiver = PageTextReceiver.new(fonts)
        walk(text_receiver)
        text_receiver.content
      end

      def walk(receiver)
        content_stream(receiver, raw_content)
      end

      # returns the raw content stream for this page. This is plumbing, nothing to
      # see unless you're a PDF nerd like me.
      #
      def raw_content
        contents = ohash.object(@page_obj[:Contents])
        [contents].flatten.compact.map { |obj|
          ohash.object(obj)
        }.map { |obj|
          obj.unfiltered_data
        }.join
      end

      private

      def ohash
        @ohash
      end

      def root
        root ||= ohash.object(@ohash.trailer[:Root])
      end

      def content_stream(receiver, instructions)
        buffer       = Buffer.new(StringIO.new(instructions), :content_stream => true)
        parser       = Parser.new(buffer, @ohash)
        params       = []

        while (token = parser.parse_token(PagesStrategy::OPERATORS))
          if token.kind_of?(Token) and PagesStrategy::OPERATORS.has_key?(token)
            callback(receiver, PagesStrategy::OPERATORS[token], params)

            params.clear
          else
            params << token
          end
        end
      rescue EOFError => e
        raise MalformedPDFError, "End Of File while processing a content stream"
      end

      def resources
        hash = {}
        page_with_ancestors.each do |obj|
          hash.merge!(obj[:Resources]) if obj[:Resources]
        end
        hash
      end

      # calls the name callback method on the receiver class with params as the arguments
      #
      def callback (receiver, name, params=[])
        receiver.send(name, *params) if receiver.respond_to?(name)
      end

      def page_with_ancestors(obj = nil)
        obj = ohash.object(obj)
        if obj.nil?
          [@page_obj] + page_with_ancestors(@page_obj[:Parent])
        elsif obj[:Parent]
          [obj] + page_with_ancestors(obj[:Parent])
        else
          [obj]
        end
      end

      def get_page_obj(page_num)
        pages = ohash.object(root[:Pages])
        page_array = get_page_objects(pages).flatten
        ohash.object(page_array[page_num - 1])
      end

      # returns a nested array of objects for all pages in this PDF.
      #
      def get_page_objects(obj)
        obj = ohash.object(obj)
        if obj[:Type] == :Page
          obj
        elsif obj[:Type] == :Pages
          obj[:Kids].map { |kid| get_page_objects(kid) }
        end
      end

    end
  end
end
