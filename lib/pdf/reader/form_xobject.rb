# coding: utf-8
# typed: true
# frozen_string_literal: true

require 'digest/md5'

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
      extend Forwardable

      #: untyped
      attr_reader :xobject

      def_delegators :resources, :color_spaces
      def_delegators :resources, :fonts
      def_delegators :resources, :graphic_states
      def_delegators :resources, :patterns
      def_delegators :resources, :procedure_sets
      def_delegators :resources, :properties
      def_delegators :resources, :shadings
      def_delegators :resources, :xobjects

      #: (untyped, untyped, ?Hash[untyped, untyped]) -> void
      def initialize(page, xobject, options = {})
        @page    = page
        @objects = page.objects
        @cache   = options[:cache] || {}
        @xobject = @objects.deref_stream(xobject)
      end

      # return a hash of fonts used on this form.
      #
      # The keys are the font labels used within the form content stream.
      #
      # The values are a PDF::Reader::Font instances that provide access
      # to most available metrics for each font.
      #
      #: () -> untyped
      def font_objects
        raw_fonts = @objects.deref_hash(fonts)
        ::Hash[raw_fonts.map { |label, font|
          [label, PDF::Reader::Font.new(@objects, @objects.deref_hash(font) || {})]
        }]
      end

      # processes the raw content stream for this form in sequential order and
      # passes callbacks to the receiver objects.
      #
      # See the comments on PDF::Reader::Page#walk for more detail.
      #
      #: (*untyped) -> untyped
      def walk(*receivers)
        receivers = receivers.map { |receiver|
          ValidatingReceiver.new(receiver)
        }
        content_stream(receivers, raw_content)
      end

      # returns the raw content stream for this page. This is plumbing, nothing to
      # see here unless you're a PDF nerd like me.
      #
      #: () -> untyped
      def raw_content
        @xobject.unfiltered_data
      end

      private

      # Returns the resources that accompany this form.
      #
      #: () -> untyped
      def resources
        @resources ||= Resources.new(@objects, @objects.deref_hash(@xobject.hash[:Resources]) || {})
      end

      #: (untyped, untyped, ?Array[untyped]) -> untyped
      def callback(receivers, name, params=[])
        receivers.each do |receiver|
          receiver.send(name, *params) if receiver.respond_to?(name)
        end
      end

      #: () -> untyped
      def content_stream_md5
        @content_stream_md5 ||= Digest::MD5.hexdigest(raw_content)
      end

      #: () -> untyped
      def cached_tokens_key
        @cached_tokens_key ||= "tokens-#{content_stream_md5}"
      end

      #: () -> untyped
      def tokens
        @cache[cached_tokens_key] ||= begin
                      buffer = Buffer.new(StringIO.new(raw_content), :content_stream => true)
                      parser = Parser.new(buffer, @objects)
                      result = []
                      while (token = parser.parse_token(PagesStrategy::OPERATORS))
                        result << token
                      end
                      result
                    end
      end

      #: (untyped, untyped) -> untyped
      def content_stream(receivers, instructions)
        params       = []

        tokens.each do |token|
          if token.kind_of?(Token) and PagesStrategy::OPERATORS.has_key?(token)
            callback(receivers, PagesStrategy::OPERATORS[token], params)
            params.clear
          else
            params << token
          end
        end
      rescue EOFError
        raise MalformedPDFError, "End Of File while processing a content stream"
      end
    end
  end
end
