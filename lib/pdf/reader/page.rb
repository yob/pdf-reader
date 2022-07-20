# coding: utf-8
# typed: strict
# frozen_string_literal: true

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
      extend Forwardable

      # lowlevel hash-like access to all objects in the underlying PDF
      attr_reader :objects

      # the raw PDF object that defines this page
      attr_reader :page_object

      # a Hash-like object for storing cached data. Generally this is scoped to
      # the current document and is used to avoid repeating expensive
      # operations
      attr_reader :cache

      def_delegators :resources, :color_spaces
      def_delegators :resources, :fonts
      def_delegators :resources, :graphic_states
      def_delegators :resources, :patterns
      def_delegators :resources, :procedure_sets
      def_delegators :resources, :properties
      def_delegators :resources, :shadings
      def_delegators :resources, :xobjects

      # creates a new page wrapper.
      #
      # * objects - an ObjectHash instance that wraps a PDF file
      # * pagenum - an int specifying the page number to expose. 1 indexed.
      #
      def initialize(objects, pagenum, options = {})
        @objects, @pagenum = objects, pagenum
        @page_object = objects.deref_hash(objects.page_references[pagenum - 1]) || {}
        @cache       = options[:cache] || {}

        if @page_object.empty?
          raise InvalidPageError, "Invalid page: #{pagenum}"
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

      # Returns the attributes that accompany this page, including
      # attributes inherited from parents.
      #
      def attributes
        @attributes ||= {}.tap { |hash|
          page_with_ancestors.reverse.each do |obj|
            hash.merge!(@objects.deref_hash(obj) || {})
          end
        }
        # This shouldn't be necesary, but some non compliant PDFs leave MediaBox
        # out. Assuming 8.5" x 11" is what Acobat does, so we do it too.
        @attributes[:MediaBox] ||= [0,0,612,792]
        @attributes
      end

      def height
        rect = Rectangle.new(*attributes[:MediaBox])
        rect.apply_rotation(rotate) if rotate > 0
        rect.height
      end

      def width
        rect = Rectangle.new(*attributes[:MediaBox])
        rect.apply_rotation(rotate) if rotate > 0
        rect.width
      end

      def origin
        rect = Rectangle.new(*attributes[:MediaBox])
        rect.apply_rotation(rotate) if rotate > 0

        rect.bottom_left
      end

      # Convenience method to identify the page's orientation.
      #
      def orientation
        if height > width
          "portrait"
        else
          "landscape"
        end
      end

      # returns the plain text content of this page encoded as UTF-8. Any
      # characters that can't be translated will be returned as a ▯
      #
      def text(opts = {})
        receiver = PageTextReceiver.new
        walk(receiver)
        runs = receiver.runs(opts)

        # rectangles[:MediaBox] can never be nil, but I have no easy way to tell sorbet that atm
        mediabox = rectangles[:MediaBox] || Rectangle.new(0, 0, 0, 0)

        PageLayout.new(runs, mediabox).to_s
      end
      alias :to_s :text

      def runs(opts = {})
        receiver = PageTextReceiver.new
        walk(receiver)
        receiver.runs(opts)
      end

      # processes the raw content stream for this page in sequential order and
      # passes callbacks to the receiver objects.
      #
      # This is mostly low level and you can probably ignore it unless you need
      # access to something like the raw encoded text. For an example of how
      # this can be used as a basis for higher level functionality, see the
      # text() method
      #
      # If someone was motivated enough, this method is intended to provide all
      # the data required to faithfully render the entire page. If you find
      # some required data isn't available it's a bug - let me know.
      #
      # Many operators that generate callbacks will reference resources stored
      # in the page header - think images, fonts, etc. To facilitate these
      # operators, the first available callback is page=. If your receiver
      # accepts that callback it will be passed the current
      # PDF::Reader::Page object. Use the Page#resources method to grab any
      # required resources.
      #
      # It may help to think of each page as a self contained program made up of
      # a set of instructions and associated resources. Calling walk() executes
      # the program in the correct order and calls out to your implementation.
      #
      def walk(*receivers)
        receivers = receivers.map { |receiver|
          ValidatingReceiver.new(receiver)
        }
        callback(receivers, :page=, [self])
        content_stream(receivers, raw_content)
      end

      # returns the raw content stream for this page. This is plumbing, nothing to
      # see here unless you're a PDF nerd like me.
      #
      def raw_content
        contents = objects.deref_stream_or_array(@page_object[:Contents])
        [contents].flatten.compact.map { |obj|
          objects.deref_stream(obj)
        }.compact.map { |obj|
          obj.unfiltered_data
        }.join(" ")
      end

      # returns the angle to rotate the page clockwise. Always 0, 90, 180 or 270
      #
      def rotate
        value = attributes[:Rotate].to_i
        case value
        when 0, 90, 180, 270
          value
        else
          0
        end
      end

      # returns the "boxes" that define the page object.
      # values are defaulted according to section 7.7.3.3 of the PDF Spec 1.7
      #
      # DEPRECATED. Recommend using Page#rectangles instead
      #
      def boxes
        # In ruby 2.4+ we could use Hash#transform_values
        Hash[rectangles.map{ |k,rect| [k,rect.to_a] } ]
      end

      # returns the "boxes" that define the page object.
      # values are defaulted according to section 7.7.3.3 of the PDF Spec 1.7
      #
      def rectangles
        # attributes[:MediaBox] can never be nil, but I have no easy way to tell sorbet that atm
        mediabox = objects.deref_array_of_numbers(attributes[:MediaBox]) || []
        cropbox = objects.deref_array_of_numbers(attributes[:CropBox]) || mediabox
        bleedbox = objects.deref_array_of_numbers(attributes[:BleedBox]) || cropbox
        trimbox = objects.deref_array_of_numbers(attributes[:TrimBox]) || cropbox
        artbox = objects.deref_array_of_numbers(attributes[:ArtBox]) || cropbox

        begin
          mediarect = Rectangle.from_array(mediabox)
          croprect = Rectangle.from_array(cropbox)
          bleedrect = Rectangle.from_array(bleedbox)
          trimrect = Rectangle.from_array(trimbox)
          artrect = Rectangle.from_array(artbox)
        rescue ArgumentError => e
          raise MalformedPDFError, e.message
        end

        if rotate > 0
          mediarect.apply_rotation(rotate)
          croprect.apply_rotation(rotate)
          bleedrect.apply_rotation(rotate)
          trimrect.apply_rotation(rotate)
          artrect.apply_rotation(rotate)
        end

        {
          MediaBox: mediarect,
          CropBox: croprect,
          BleedBox: bleedrect,
          TrimBox: trimrect,
          ArtBox: artrect,
        }
      end

      private

      def root
        @root ||= objects.deref_hash(@objects.trailer[:Root]) || {}
      end

      # Returns the resources that accompany this page. Includes
      # resources inherited from parents.
      #
      def resources
        @resources ||= Resources.new(@objects, @objects.deref_hash(attributes[:Resources]) || {})
      end

      def content_stream(receivers, instructions)
        buffer       = Buffer.new(StringIO.new(instructions), :content_stream => true)
        parser       = Parser.new(buffer, @objects)
        params       = []

        while (token = parser.parse_token(PagesStrategy::OPERATORS))
          if token.kind_of?(Token) && method_name = PagesStrategy::OPERATORS[token]
            callback(receivers, method_name, params)
            params.clear
          else
            params << token
          end
        end
      rescue EOFError
        raise MalformedPDFError, "End Of File while processing a content stream"
      end

      # calls the name callback method on each receiver object with params as the arguments
      #
      # The silly style here is because sorbet won't let me use splat arguments
      #
      def callback(receivers, name, params=[])
        receivers.each do |receiver|
          if receiver.respond_to?(name)
            case params.size
            when 0 then receiver.send(name)
            when 1 then receiver.send(name, params[0])
            when 2 then receiver.send(name, params[0], params[1])
            when 3 then receiver.send(name, params[0], params[1], params[2])
            when 4 then receiver.send(name, params[0], params[1], params[2], params[3])
            when 5 then receiver.send(name, params[0], params[1], params[2], params[3], params[4])
            when 6 then receiver.send(name, params[0], params[1], params[2], params[3], params[4], params[5])
            when 7 then receiver.send(name, params[0], params[1], params[2], params[3], params[4], params[5], params[6])
            when 8 then receiver.send(name, params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7])
            when 9 then receiver.send(name, params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8])
            else
              receiver.send(name, params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9])
            end
          end
        end
      end

      def page_with_ancestors
        [ @page_object ] + ancestors
      end

      def ancestors(origin = @page_object[:Parent])
        if origin.nil?
          []
        else
          obj = objects.deref_hash(origin)
          if obj.nil?
            raise MalformedPDFError, "parent mus not be nil"
          end
          [ select_inheritable(obj) ] + ancestors(obj[:Parent])
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
