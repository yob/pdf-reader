# coding: utf-8

module PDF
  class Reader

    # High level representation of a single PDF form xobject. Form xobjects
    # are contained pieces of content that can be inserted onto multiple
    # pages. They're generally used as a space efficient way to store
    # repetative content (like logos, header, footers, etc).
    #
    # This behaves and looks much like a limited PDF::Reader::Page class.
    #
    class FormXObject
      include ResourceMethods

      def initialize(page, xobject)
        @page    = page
        @objects = page.objects
        @xobject = @objects.deref(xobject)
      end

      # return a hash of fonts used on this form.
      #
      # The keys are the font labels used within the form content stream.
      #
      # The values are a PDF::Reader::Font instances that provide access
      # to most available metrics for each font.
      #
      def font_objects
        raw_fonts = @objects.deref(resources[:Font] || {})
        ::Hash[raw_fonts.map { |label, font|
          [label, PDF::Reader::Font.new(@objects, @objects.deref(font))]
        }]
      end

      # processes the raw content stream for this form in sequential order and
      # passes callbacks to the receiver objects.
      #
      # See the comments on PDF::Reader::Page#walk for more detail.
      #
      def walk(*receivers)
        content_stream(receivers, raw_content)
      end

      # returns the raw content stream for this page. This is plumbing, nothing to
      # see here unless you're a PDF nerd like me.
      #
      def raw_content
        @xobject.unfiltered_data
      end

      private

      # Returns the resources that accompany this form.
      #
      def resources
        @resources ||= @objects.deref(@xobject.hash[:Resources]) || {}
      end

      def callback(receivers, name, params=[])
        receivers.each do |receiver|
          receiver.send(name, *params) if receiver.respond_to?(name)
        end
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
    end
  end
end
