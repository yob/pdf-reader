# typed: strong
module PDF
  class Reader
    sig { returns(PDF::Reader::ObjectHash) }
    attr_reader :objects

    sig { params(input: T.any(String, Tempfile, IO), opts: T::Hash[T.untyped, T.untyped]).void }
    def initialize(input, opts = {})
      @cache = T.let(T.unsafe(nil), PDF::Reader::ObjectCache)
      @objects = T.let(T.unsafe(nil), PDF::Reader::ObjectHash)
      @page_count = T.let(T.unsafe(nil), T.nilable(Integer))
      @root = T.let(T.unsafe(nil), T.nilable(T.nilable(T::Hash[Symbol, T.untyped])))
    end

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    def info; end

    sig { returns(T.nilable(String)) }
    def metadata; end

    sig { returns(Integer) }
    def page_count; end

    sig { returns(Float) }
    def pdf_version; end

    sig { params(input: T.any(String, Tempfile, IO), opts: T::Hash[T.untyped, T.untyped], block: T.proc.params(arg0: PDF::Reader).void).returns(T.untyped) }
    def self.open(input, opts = {}, &block); end

    sig { returns(T::Array[PDF::Reader::Page]) }
    def pages; end

    sig { params(num: Integer).returns(PDF::Reader::Page) }
    def page(num); end

    sig { params(obj: T.untyped).returns(T.untyped) }
    def doc_strings_to_utf8(obj); end

    sig { params(str: String).returns(T::Boolean)}
    def has_utf16_bom?(str); end

    sig { params(obj: String).returns(String) }
    def pdfdoc_to_utf8(obj); end

    sig { params(obj: String).returns(String) }
    def utf16_to_utf8(obj); end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def root; end

    class AesV2SecurityHandler
      sig { params(key: String).void }
      def initialize(key)
        @encrypt_key = T.let(T.unsafe(nil), String)
      end

      sig { params(buf: String, ref: PDF::Reader::Reference).returns(String) }
      def decrypt(buf, ref); end
    end

    class AesV3SecurityHandler
      sig { params(key: String).void }
      def initialize(key)
        @encrypt_key = T.let(T.unsafe(nil), String)
        @cipher = T.let(T.unsafe(nil), String)
      end

      sig { params(buf: String, ref: PDF::Reader::Reference).returns(String) }
      def decrypt(buf, ref); end
    end

    class BoundingRectangleRunsFilter
      sig { params(runs: T::Array[PDF::Reader::TextRun], rect: PDF::Reader::Rectangle).returns(T::Array[PDF::Reader::TextRun]) }
      def self.runs_within_rect(runs, rect); end
    end

    class Buffer
      TOKEN_WHITESPACE = T.let(T.unsafe(nil), T::Array[Integer])
      TOKEN_DELIMITER = T.let(T.unsafe(nil), T::Array[Integer])
      LEFT_PAREN = T.let(T.unsafe(nil), String)
      LESS_THAN = T.let(T.unsafe(nil), String)
      STREAM = T.let(T.unsafe(nil), String)
      ID = T.let(T.unsafe(nil), String)
      FWD_SLASH = T.let(T.unsafe(nil), String)
      NULL_BYTE = T.let(T.unsafe(nil), String)
      CR = T.let(T.unsafe(nil), String)
      LF = T.let(T.unsafe(nil), String)
      CRLF = T.let(T.unsafe(nil), String)
      WHITE_SPACE = T.let(T.unsafe(nil), T::Array[String])
      TRAILING_BYTECOUNT = T.let(T.unsafe(nil), Integer)
      DIGITS_ONLY = T.let(T.unsafe(nil), Regexp)

      sig { returns(Integer) }
      attr_reader :pos

      sig { params(io: T.any(StringIO, Tempfile, IO), opts: T::Hash[Symbol, T.untyped]).void }
      def initialize(io, opts = {})
        @pos = T.let(T.unsafe(nil), Integer)
        @tokens = T.let(T.unsafe(nil), T::Array[T.any(String, PDF::Reader::Reference)])
        @io = T.let(T.unsafe(nil), T.any(StringIO, Tempfile, IO))
        @in_content_stream = T.let(T.unsafe(nil), T::Boolean)
      end

      sig { returns(T::Boolean) }
      def empty?; end

      sig { params(bytes: Integer, opts: T::Hash[Symbol, T.untyped]).returns(T.nilable(String)) }
      def read(bytes, opts = {}); end

      sig { returns(T.any(NilClass, String, PDF::Reader::Reference)) }
      def token; end

      sig { returns(Integer) }
      def find_first_xref_offset; end

      sig { void }
      def check_size_is_non_zero; end

      sig { returns(T::Boolean) }
      def in_content_stream?; end

      sig { void }
      def reset_pos; end

      sig { void }
      def save_pos; end

      sig { void }
      def prepare_tokens; end

      sig { returns(Symbol) }
      def state; end

      sig { void }
      def merge_indirect_reference; end

      sig { void }
      def prepare_inline_token; end

      sig { void }
      def prepare_hex_token; end

      sig { void }
      def prepare_literal_token; end

      sig { void }
      def prepare_regular_token; end

      sig { returns(T.nilable(Integer)) }
      def peek_byte; end
    end

    class CidWidths
      sig { params(default: Numeric, array: T::Array[Numeric]).void }
      def initialize(default, array)
        @widths = T.let(T.unsafe(nil), T::Hash[Numeric, Numeric])
      end

      sig { params(default: Numeric, array: T::Array[Numeric]).returns(T::Hash[Numeric, Numeric]) }
      def parse_array(default, array); end

      sig { params(first: Integer, widths: T::Array[Numeric]).returns(T::Hash[Numeric, Numeric]) }
      def parse_first_form(first, widths); end

      sig { params(first: Integer, final: Integer, width: Numeric).returns(T::Hash[Numeric, Numeric]) }
      def parse_second_form(first, final, width); end
    end

    class CMap
      CMAP_KEYWORDS = T.let(T.unsafe(nil), T::Hash[String, Symbol])

      sig { returns(T.untyped) }
      attr_reader :map

      sig { params(data: String).void }
      def initialize(data)
        @map = T.let(T.unsafe(nil), T::Hash[Integer, T::Array[Integer]])
      end

      sig { params(data: String, initial_mode: Symbol).void }
      def process_data(data, initial_mode = :none); end

      sig { returns(Integer) }
      def size; end

      sig { params(c: Integer).returns(T::Array[Integer]) }
      def decode(c); end

      sig { params(instructions: String).returns(PDF::Reader::Parser) }
      def build_parser(instructions); end

      sig { params(str: String).returns(T::Array[Integer]) }
      def str_to_int(str); end

      sig { params(instructions: T::Array[String]).void }
      def process_bfchar_instructions(instructions); end

      sig { params(instructions: T::Array[T.any(T::Array[String], String)]).void }
      def process_bfrange_instructions(instructions); end

      sig { params(start_code: String, end_code: String, dst: String).void }
      def bfrange_type_one(start_code, end_code, dst); end

      sig { params(start_code: String, end_code: String, dst: T::Array[String]).void }
      def bfrange_type_two(start_code, end_code, dst); end
    end

    class Encoding
      CONTROL_CHARS = T.let(T.unsafe(nil), T::Array[Integer])
      UNKNOWN_CHAR = T.let(T.unsafe(nil), Integer)

      sig { returns(String) }
      attr_reader :unpack

      sig { params(enc: T.untyped).void }
      def initialize(enc)
        @mapping = T.let(T.unsafe(nil), T::Hash[Integer, Integer])
        @unpack = T.let(T.unsafe(nil), String)
        @enc_name = T.let(T.unsafe(nil), Symbol)
        @string_cache = T.let(T.unsafe(nil), T::Hash[Integer, String])
        @map_file = T.let(T.unsafe(nil), T.nilable(String))
        @differences = T.let(T.unsafe(nil), T.nilable(T::Hash[Integer, Integer]))
        @glyphlist = T.let(T.unsafe(nil), T.nilable(PDF::Reader::GlyphHash))
      end

      sig { params(diff: T::Array[T.any(Integer, Symbol)]).returns(T::Hash[Integer, Integer]) }
      def differences=(diff); end

      sig { returns(T::Hash[Integer, Integer]) }
      def differences; end

      sig { params(str: String).returns(String) }
      def to_utf8(str); end

      sig { params(glyph_code: Integer).returns(String) }
      def int_to_utf8_string(glyph_code); end

      sig { params(glyph_code: Integer).returns(T::Array[Symbol]) }
      def int_to_name(glyph_code); end

      sig { returns(T::Hash[Integer, Integer]) }
      def default_mapping; end

      sig { params(glyph_code: Integer).returns(String) }
      def internal_int_to_utf8_string(glyph_code); end

      sig { returns(T::Boolean) }
      def utf8_conversion_impossible?; end

      sig { params(times: Integer).returns(String) }
      def little_boxes(times); end

      sig { params(str: String).returns(String) }
      def convert_to_utf8(str); end

      sig { params(enc: T.untyped).returns(String) }
      def get_unpack(enc); end

      sig { params(enc: T.untyped).returns(T.nilable(String)) }
      def get_mapping_file(enc); end

      sig { returns(PDF::Reader::GlyphHash) }
      def glyphlist; end

      sig { params(file: String).void }
      def load_mapping(file); end
    end

    class Error
      sig { params(lvalue: T.untyped, rvalue: T.untyped, chars: T.untyped).returns(T.untyped) }
      def self.str_assert(lvalue, rvalue, chars = nil); end

      sig { params(lvalue: T.untyped, rvalue: T.untyped, chars: T.untyped).returns(T.untyped) }
      def self.str_assert_not(lvalue, rvalue, chars = nil); end

      sig { params(lvalue: T.untyped, rvalue: T.untyped).returns(T.untyped) }
      def self.assert_equal(lvalue, rvalue); end

      sig { params(object: Object, name: String, klass: Module).void }
      def self.validate_type(object, name, klass); end

      sig { params(object: Object, name: String, klass: Module).void }
      def self.validate_type_as_malformed(object, name, klass); end

      sig { params(object: Object, name: String).void }
		  def self.validate_not_nil(object, name); end
    end

    class MalformedPDFError < RuntimeError
    end

    class InvalidPageError < ArgumentError
    end

    class InvalidObjectError < MalformedPDFError
    end

    class UnsupportedFeatureError < RuntimeError
    end

    class EncryptedPDFError < UnsupportedFeatureError
    end

    class Font
      sig { returns(T.nilable(Symbol)) }
      attr_accessor :subtype

      sig { returns(PDF::Reader::Encoding) }
      attr_accessor :encoding

      sig { returns(T::Array[PDF::Reader::Font]) }
      attr_accessor :descendantfonts

      sig { returns(PDF::Reader::CMap) }
      attr_accessor :tounicode

      sig { returns(T::Array[Integer]) }
      attr_reader :widths

      sig { returns(T.nilable(Integer)) }
      attr_reader :first_char

      sig { returns(T.nilable(Integer)) }
      attr_reader :last_char

      sig { returns(T.nilable(Symbol)) }
      attr_reader :basefont

      sig { returns(T.nilable(PDF::Reader::FontDescriptor)) }
      attr_reader :font_descriptor

      sig { returns(T::Array[Numeric]) }
      attr_reader :cid_widths

      sig { returns(Numeric) }
      attr_reader :cid_default_width

      sig { params(ohash: PDF::Reader::ObjectHash, obj: T::Hash[Symbol, T.untyped]).void }
      def initialize(ohash, obj); end

      sig { params(params: T.any(Integer, String, T::Array[T.untyped])).returns(String) }
      def to_utf8(params); end

      sig { params(data: String).returns(T::Array[T.nilable(T.any(Numeric, String))]) }
      def unpack(data); end

      sig { params(code_point: T.any(String, Integer)).returns(T.untyped) }
      def glyph_width(code_point); end

      sig { params(font_name: Symbol).returns(PDF::Reader::Encoding) }
      def default_encoding(font_name); end

      sig {
        returns(
          T.any(
            PDF::Reader::WidthCalculator::BuiltIn,
            PDF::Reader::WidthCalculator::Composite,
            PDF::Reader::WidthCalculator::TrueType,
            PDF::Reader::WidthCalculator::TypeOneOrThree,
            PDF::Reader::WidthCalculator::TypeZero,
          )
        )
      }
      def build_width_calculator; end

      sig { params(obj: T.untyped).void }
      def extract_base_info(obj); end

      sig { params(obj: T.untyped).void }
      def extract_descriptor(obj); end

      sig { params(obj: T.untyped).void }
      def extract_descendants(obj); end

      sig { params(params: T.any(Integer, String, T::Array[T.untyped])).returns(String) }
      def to_utf8_via_cmap(params); end

      sig { params(params: T.any(Integer, String, T::Array[T.untyped])).returns(String) }
      def to_utf8_via_encoding(params); end
    end

    class FontDescriptor
      sig { returns(String) }
      attr_reader :font_name

      sig { returns(T.nilable(String)) }
      attr_reader :font_family

      sig { returns(Symbol) }
      attr_reader :font_stretch

      sig { returns(Numeric) }
      attr_reader :font_weight

      sig { returns(T::Array[Numeric]) }
      attr_reader :font_bounding_box

      sig { returns(Numeric) }
      attr_reader :cap_height

      sig { returns(Numeric) }
      attr_reader :ascent

      sig { returns(Numeric) }
      attr_reader :descent

      sig { returns(Numeric) }
      attr_reader :leading

      sig { returns(Numeric) }
      attr_reader :avg_width

      sig { returns(Numeric) }
      attr_reader :max_width

      sig { returns(Numeric) }
      attr_reader :missing_width

      sig { returns(T.nilable(Numeric)) }
      attr_reader :italic_angle

      sig { returns(T.nilable(Numeric)) }
      attr_reader :stem_v

      sig { returns(T.nilable(Numeric)) }
      attr_reader :x_height

      sig { returns(Integer) }
      attr_reader :font_flags

      sig { params(ohash: PDF::Reader::ObjectHash, fd_hash: T::Hash[T.untyped, T.untyped]).void }
      def initialize(ohash, fd_hash); end

      sig { params(char_code: Integer).returns(Numeric) }
      def glyph_width(char_code); end

      sig { returns(Numeric) }
      def glyph_to_pdf_scale_factor; end

      sig { returns(TTFunk::File) }
      def ttf_program_stream; end
    end

    class FormXObject
      sig { returns(T.untyped) }
      attr_reader :xobject

      sig { params(page: T.untyped, xobject: T.untyped, options: T.untyped).void }
      def initialize(page, xobject, options = {}); end

      sig { returns(T.untyped) }
      def font_objects; end

      sig { params(receivers: T.untyped).returns(T.untyped) }
      def walk(*receivers); end

      sig { returns(T.untyped) }
      def raw_content; end

      sig { returns(T.untyped) }
      def resources; end

      sig { params(receivers: T.untyped, name: T.untyped, params: T.untyped).returns(T.untyped) }
      def callback(receivers, name, params = []); end

      sig { returns(T.untyped) }
      def content_stream_md5; end

      sig { returns(T.untyped) }
      def cached_tokens_key; end

      sig { returns(T.untyped) }
      def tokens; end

      sig { params(receivers: T.untyped, instructions: T.untyped).returns(T.untyped) }
      def content_stream(receivers, instructions); end
    end

    class GlyphHash
      @@by_name_cache = T.let(T.unsafe(nil), T.nilable(T::Hash[Symbol, Integer]))
      @@by_codepoint_cache = T.let(T.unsafe(nil), T.nilable(T::Hash[Integer, T::Array[Symbol]]))

      sig { void }
      def initialize
        @by_name = T.let(T.unsafe(nil), T::Hash[Symbol, Integer])
        @by_codepoint = T.let(T.unsafe(nil), T::Hash[Integer, T::Array[Symbol]])
      end

      sig { params(name: T.nilable(Symbol)).returns(T.nilable(Integer)) }
      def name_to_unicode(name); end

      sig { params(codepoint: T.nilable(Integer)).returns(T::Array[Symbol]) }
      def unicode_to_name(codepoint); end

      sig { returns([T::Hash[Symbol, Integer], T::Hash[Integer, T::Array[Symbol]]]) }
      def load_adobe_glyph_mapping; end
    end

    class KeyBuilderV5
      sig { params(opts: T::Hash[Symbol, String]).void }
      def initialize(opts = {})
        @key_length = T.let(T.unsafe(nil), Integer)
        @owner_key = T.let(T.unsafe(nil), String)
        @user_key = T.let(T.unsafe(nil), String)
        @owner_encryption_key = T.let(T.unsafe(nil), String)
        @user_encryption_key = T.let(T.unsafe(nil), String)
      end

      sig { params(pass: String).returns(String) }
      def key(pass); end

      sig { params(password: T.untyped).returns(T.untyped) }
      def auth_owner_pass(password); end

      sig { params(password: T.untyped).returns(T.untyped) }
      def auth_user_pass(password); end

      sig { params(password: String).returns(T.nilable(String)) }
      def auth_owner_pass_r6(password); end

      sig { params(password: String).returns(T.nilable(String)) }
      def auth_user_pass_r6(password); end

      sig { params(password: String, salt: String, user_key: String).returns(String)}
      def r6_digest(password, salt, user_key = ''); end

      sig { params(str: String).returns(Integer)}
      def unpack_128bit_bigendian_int(str); end
    end

    class LZW
      CODE_EOD = 257
      CODE_CLEAR_TABLE = 256

      class BitStream
        sig { params(data: String, bits_in_chunk: Integer).void }
        def initialize(data, bits_in_chunk)
          @data = T.let(T.unsafe(nil), String)
          @bits_in_chunk = T.let(T.unsafe(nil), Integer)
          @current_pos = T.let(T.unsafe(nil), Integer)
          @bits_left_in_byte = T.let(T.unsafe(nil), Integer)

        end

        sig { params(bits_in_chunk: Integer).void }
        def set_bits_in_chunk(bits_in_chunk); end

        sig { returns(Integer) }
        def read; end
      end

      class StringTable
        sig { returns(Integer) }
        attr_reader :string_table_pos

        sig { void }
        def initialize
          @data = T.let(T.unsafe(nil), T::Hash[Integer, String])
          @string_table_pos = T.let(T.unsafe(nil), Integer)
        end

        sig { params(key: Integer).returns(T.nilable(String)) }
        def [](key); end

        sig { params(string: String).void }
        def add(string); end
      end

      sig { params(data: String).returns(String) }
      def self.decode(data); end

      sig { params(string_table: PDF::Reader::LZW::StringTable, some_code: T.nilable(Integer), other_code: T.nilable(Integer)).returns(String) }
      def self.create_new_string(string_table, some_code, other_code); end
    end

    class NullSecurityHandler
      sig { params(buf: T.untyped, _ref: T.untyped).returns(T.untyped) }
      def decrypt(buf, _ref); end
    end

    class ObjectCache
      CACHEABLE_TYPES = [:Catalog, :Page, :Pages]

      sig { returns(T.untyped) }
      attr_reader :hits

      sig { returns(T.untyped) }
      attr_reader :misses

      sig { params(lru_size: T.untyped).void }
      def initialize(lru_size = 1000); end

      sig { params(key: T.untyped).returns(T.untyped) }
      def [](key); end

      sig { params(key: T.untyped, value: T.untyped).returns(T.untyped) }
      def []=(key, value); end

      sig { params(key: T.untyped, local_default: T.untyped).returns(T.untyped) }
      def fetch(key, local_default = nil); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each(&block); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each_key(&block); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each_value(&block); end

      sig { returns(T.untyped) }
      def size; end

      sig { returns(T.untyped) }
      def empty?; end

      sig { params(key: T.untyped).returns(T.untyped) }
      def include?(key); end

      sig { params(value: T.untyped).returns(T.untyped) }
      def has_value?(value); end

      sig { returns(T.untyped) }
      def to_s; end

      sig { returns(T.untyped) }
      def keys; end

      sig { returns(T.untyped) }
      def values; end

      sig { params(key: T.untyped).returns(T.untyped) }
      def update_stats(key); end

      sig { params(obj: T.untyped).returns(T.untyped) }
      def cacheable?(obj); end
    end

    class ObjectHash
      include Enumerable

      sig { returns(T.untyped) }
      attr_accessor :default

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :trailer

      sig { returns(Float) }
      attr_reader :pdf_version

      sig { returns(
        T.any(
          PDF::Reader::NullSecurityHandler,
          PDF::Reader::AesV2SecurityHandler,
          PDF::Reader::AesV3SecurityHandler,
          PDF::Reader::Rc4SecurityHandler,
      )) }
      attr_reader :sec_handler

      sig { params(input: T.any(IO, Tempfile, StringIO, String), opts: T::Hash[Symbol, T.untyped]).void }
      def initialize(input, opts = {})
        @io = T.let(T.unsafe(nil), T.any(IO, Tempfile, StringIO))
        @xref = T.let(T.unsafe(nil), PDF::Reader::XRef)
        @pdf_version = T.let(T.unsafe(nil), Float)
        @trailer = T.let(T.unsafe(nil), T::Hash[Symbol, T.untyped])
        @cache = T.let(T.unsafe(nil), PDF::Reader::ObjectCache)
        @sec_handler = T.let(T.unsafe(nil), T.any(
          PDF::Reader::NullSecurityHandler,
          PDF::Reader::AesV2SecurityHandler,
          PDF::Reader::AesV3SecurityHandler,
          PDF::Reader::Rc4SecurityHandler,
        ))
        @page_references = T.let(T.unsafe(nil), T.nilable(T::Array[T.any(PDF::Reader::Reference, T::Hash[Symbol, T.untyped])]))
        @object_streams = T.let(T.unsafe(nil), T.nilable(T::Hash[PDF::Reader::Reference, PDF::Reader::ObjectStream]))
      end

      sig { params(ref: T.any(Integer, PDF::Reader::Reference)).returns(T.nilable(Symbol)) }
      def obj_type(ref); end

      sig { params(ref: T.any(Integer, PDF::Reader::Reference)).returns(T::Boolean) }
      def stream?(ref); end

      sig { params(key: T.any(Integer, PDF::Reader::Reference)).returns(T.untyped) }
      def [](key); end

      sig { params(key: T.untyped).returns(T.untyped) }
      def object(key); end

      sig { params(key: T.untyped).returns(T.nilable(T::Array[T.untyped])) }
      def deref_array(key); end

      sig { params(key: T.untyped).returns(T.nilable(T::Array[Numeric])) }
      def deref_array_of_numbers(key); end

      sig { params(key: T.untyped).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
      def deref_hash(key); end

      sig { params(key: T.untyped).returns(T.nilable(Symbol)) }
      def deref_name(key); end

      sig { params(key: T.untyped).returns(T.any(Symbol, T::Array[T.untyped], NilClass)) }
      def deref_name_or_array(key); end

      sig { params(key: T.untyped).returns(T.nilable(Integer)) }
      def deref_integer(key); end

      sig { params(key: T.untyped).returns(T.nilable(Numeric)) }
      def deref_number(key); end

      sig { params(key: T.untyped).returns(T.nilable(PDF::Reader::Stream)) }
      def deref_stream(key); end

      sig { params(key: T.untyped).returns(T.nilable(String)) }
      def deref_string(key); end

      sig { params(key: T.untyped).returns(T.any(PDF::Reader::Stream, T::Array[T.untyped], NilClass)) }
      def deref_stream_or_array(key); end

      sig { params(key: T.untyped).returns(T.untyped) }
      def deref!(key); end

      sig { params(key: T.untyped).returns(T.nilable(T::Array[T.untyped])) }
      def deref_array!(key); end

      sig { params(key: T.untyped).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
      def deref_hash!(key); end

      sig { params(key: T.untyped, local_default: T.untyped).returns(T.untyped) }
      def fetch(key, local_default = nil); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each(&block); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each_key(&block); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each_value(&block); end

      sig { returns(Integer) }
      def size; end

      sig { returns(T::Boolean) }
      def empty?; end

      sig { params(check_key: T.untyped).returns(T::Boolean) }
      def has_key?(check_key); end

      sig { params(value: T.untyped).returns(T::Boolean) }
      def has_value?(value); end

      sig { returns(String) }
      def to_s; end

      sig { returns(T::Array[PDF::Reader::Reference]) }
      def keys; end

      sig { returns(T.untyped) }
      def values; end

      sig { params(ids: T.untyped).returns(T.untyped) }
      def values_at(*ids); end

      sig { returns(T.untyped) }
      def to_a; end

      sig { returns(T::Array[T.any(PDF::Reader::Reference, T::Hash[Symbol, T.untyped])]) }
      def page_references; end

      sig { returns(T::Boolean) }
      def encrypted?; end

      sig { returns(T::Boolean) }
      def sec_handler?; end

      sig { params(key: T.untyped).returns(T.untyped) }
      def fetch_object(key); end

      sig { params(key: T.untyped).returns(T.untyped) }
      def fetch_object_stream(key); end

      sig { params(key: T.untyped, seen: T.untyped).returns(T.untyped) }
      def deref_internal!(key, seen); end

      sig { params(ref: T.untyped, obj: T.untyped).returns(T.untyped) }
      def decrypt(ref, obj); end

      sig { params(offset: Integer).returns(PDF::Reader::Buffer) }
      def new_buffer(offset = 0); end

      sig { returns(T.untyped) }
      def xref; end

      sig { returns(T.untyped) }
      def object_streams; end

      sig { params(obj: T.any(PDF::Reader::Reference, T::Hash[Symbol, T.untyped])).returns(T::Array[T.any(PDF::Reader::Reference, T::Hash[Symbol, T.untyped])]) }
      def get_page_objects(obj); end

      sig { returns(Float) }
      def read_version; end

      sig { params(input: T.any(IO, Tempfile, StringIO, String)).returns(T.any(IO, Tempfile, StringIO)) }
      def extract_io_from(input); end

      sig { params(input: String).returns(String) }
      def read_as_binary(input); end
    end

    class ObjectStream
      sig { params(stream: PDF::Reader::Stream).void }
      def initialize(stream)
        @dict = T.let(T.unsafe(nil), T::Hash[Symbol, T.untyped])
        @data = T.let(T.unsafe(nil), String)
        @offsets = T.let(T.unsafe(nil), T.nilable(T::Hash[Integer, Integer]))
        @buffer = T.let(T.unsafe(nil), T.nilable(PDF::Reader::Buffer))
      end

      sig {
        params(objid: Integer).returns(
          T.any(PDF::Reader::Reference, PDF::Reader::Token, Numeric, String, Symbol, T::Array[T.untyped], T::Hash[T.untyped, T.untyped], NilClass)
        )
      }
      def [](objid); end

      sig { returns(Integer) }
      def size; end

      sig { returns(T::Hash[Integer, Integer]) }
      def offsets; end

      sig { returns(Integer) }
      def first; end

      sig { returns(PDF::Reader::Buffer) }
      def buffer; end
    end

    class OverlappingRunsFilter
      OVERLAPPING_THRESHOLD = T.let(T.unsafe(nil), Float)

      sig { params(runs: T::Array[PDF::Reader::TextRun]).returns(T::Array[PDF::Reader::TextRun]) }
      def self.exclude_redundant_runs(runs); end

      sig { params(sweep_line_status: T::Array[PDF::Reader::TextRun], event_point: PDF::Reader::EventPoint).returns(T::Boolean) }
      def self.detect_intersection(sweep_line_status, event_point); end
    end

    class NoTextFilter
      sig { params(runs: T::Array[PDF::Reader::TextRun]).returns(T::Array[PDF::Reader::TextRun]) }
      def self.exclude_empty_strings(runs); end
    end

    class EventPoint
      sig { returns(Numeric) }
      attr_reader :x

      sig { returns(PDF::Reader::TextRun) }
      attr_reader :run

      sig { params(x: Numeric, run: PDF::Reader::TextRun).void }
      def initialize(x, run)
        @x = T.let(T.unsafe(nil), Numeric)
        @run = T.let(T.unsafe(nil), PDF::Reader::TextRun)
      end

      sig { returns(T::Boolean) }
      def start?; end
    end

    class Page
      sig { returns(PDF::Reader::ObjectHash) }
      attr_reader :objects

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :page_object

      sig { returns(T.any(PDF::Reader::ObjectCache, T::Hash[T.untyped, T.untyped])) }
      attr_reader :cache

      sig { params(objects: PDF::Reader::ObjectHash, pagenum: Integer, options: T::Hash[Symbol, T.untyped]).void }
      def initialize(objects, pagenum, options = {})
        @objects = T.let(T.unsafe(nil), PDF::Reader::ObjectHash)
        @pagenum = T.let(T.unsafe(nil), Integer)
        @page_object = T.let(T.unsafe(nil), T::Hash[Symbol, T.untyped])
        @cache = T.let(T.unsafe(nil), T.any(PDF::Reader::ObjectCache, T::Hash[T.untyped, T.untyped]))
        @attributes = T.let(T.unsafe(nil), T.nilable(T::Hash[Symbol, T.untyped]))
        @root = T.let(T.unsafe(nil), T.nilable(T::Hash[Symbol, T.untyped]))
        @resources = T.let(T.unsafe(nil), T.nilable(PDF::Reader::Resources))
      end

      sig { returns(Integer) }
      def number; end

      sig { returns(String) }
      def inspect; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def attributes; end

      sig { returns(Numeric) }
      def height; end

      sig { returns(Numeric) }
      def width; end

      sig { returns(String) }
      def orientation; end

      sig { returns(T::Array[Numeric]) }
      def origin; end

      sig { params(opts: T::Hash[Symbol, T.untyped]).returns(T::Array[PDF::Reader::TextRun]) }
      def runs(opts = {}); end

      sig { params(opts: T::Hash[Symbol, T.untyped]).returns(String) }
      def text(opts = {}); end

      sig { params(receivers: T.untyped).void }
      def walk(*receivers); end

      sig { returns(String) }
      def raw_content; end

      sig { returns(Integer) }
      def rotate; end

      sig { returns(T::Hash[Symbol, T::Array[Numeric]]) }
      def boxes; end

      sig { returns(T::Hash[Symbol, PDF::Reader::Rectangle]) }
      def rectangles; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def root; end

      sig { returns(PDF::Reader::Resources) }
      def resources; end

      sig { params(receivers: T::Array[T.untyped], instructions: String).void }
      def content_stream(receivers, instructions); end

      sig { params(receivers: T::Array[Object], name: Symbol, params: T::Array[T.untyped]).void }
      def callback(receivers, name, params = []); end

      sig { returns(T.untyped) }
      def page_with_ancestors; end

      sig { params(origin: T.untyped).returns(T.untyped) }
      def ancestors(origin = @page_object[:Parent]); end

      sig { params(obj: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
      def select_inheritable(obj); end
    end

    class PageLayout
      DEFAULT_FONT_SIZE = T.let(T.unsafe(nil), Numeric)

      sig { params(runs: T::Array[PDF::Reader::TextRun], mediabox: T.any(T::Array[Numeric], PDF::Reader::Rectangle)).void }
      def initialize(runs, mediabox)
        @mediabox = T.let(T.unsafe(nil), PDF::Reader::Rectangle)
        @runs = T.let(T.unsafe(nil), T::Array[PDF::Reader::TextRun])
        @mean_font_size = T.let(T.unsafe(nil), Numeric)
        @median_glyph_width = T.let(T.unsafe(nil), Numeric)
        @x_offset = T.let(T.unsafe(nil), Numeric)
        @y_offset = T.let(T.unsafe(nil), Numeric)
        @row_count = T.let(T.unsafe(nil), T.nilable(Integer))
        @col_count = T.let(T.unsafe(nil), T.nilable(Integer))
        @row_multiplier = T.let(T.unsafe(nil), T.nilable(Numeric))
        @col_multiplier = T.let(T.unsafe(nil), T.nilable(Numeric))
      end

      sig { returns(String) }
      def to_s; end

      sig { params(rows: T.untyped).returns(T.untyped) }
      def interesting_rows(rows); end

      sig { returns(T.untyped) }
      def row_count; end

      sig { returns(T.untyped) }
      def col_count; end

      sig { returns(T.untyped) }
      def row_multiplier; end

      sig { returns(T.untyped) }
      def col_multiplier; end

      sig { params(collection: T.untyped).returns(T.untyped) }
      def mean(collection); end

      sig { params(collection: T.untyped).returns(T.untyped) }
      def median(collection); end

      sig { params(runs: T.untyped).returns(T.untyped) }
      def merge_runs(runs); end

      sig { params(chars: T::Array[PDF::Reader::TextRun]).returns(T::Array[PDF::Reader::TextRun]) }
      def group_chars_into_runs(chars); end

      sig { params(haystack: T.untyped, needle: T.untyped, index: T.untyped).returns(T.untyped) }
      def local_string_insert(haystack, needle, index); end

      sig { params(mediabox: T.untyped).returns(T.untyped) }
      def process_mediabox(mediabox); end

      sig { returns(Numeric) }
      def page_width; end

      sig { returns(Numeric) }
      def page_height; end
    end

    class PageState
      DEFAULT_GRAPHICS_STATE = {
        :char_spacing   => 0,
        :word_spacing   => 0,
        :h_scaling      => 1.0,
        :text_leading   => 0,
        :text_font      => nil,
        :text_font_size => nil,
        :text_mode      => 0,
        :text_rise      => 0,
        :text_knockout  => 0
      }

      sig { params(page: T.untyped).void }
      def initialize(page); end

      sig { returns(T.untyped) }
      def save_graphics_state; end

      sig { returns(T.untyped) }
      def restore_graphics_state; end

      sig do
        params(
          a: T.untyped,
          b: T.untyped,
          c: T.untyped,
          d: T.untyped,
          e: T.untyped,
          f: T.untyped
        ).returns(T.untyped)
      end
      def concatenate_matrix(a, b, c, d, e, f); end

      sig { returns(T.untyped) }
      def begin_text_object; end

      sig { returns(T.untyped) }
      def end_text_object; end

      sig { params(char_spacing: T.untyped).returns(T.untyped) }
      def set_character_spacing(char_spacing); end

      sig { params(h_scaling: T.untyped).returns(T.untyped) }
      def set_horizontal_text_scaling(h_scaling); end

      sig { params(label: T.untyped, size: T.untyped).returns(T.untyped) }
      def set_text_font_and_size(label, size); end

      sig { returns(T.untyped) }
      def font_size; end

      sig { params(leading: T.untyped).returns(T.untyped) }
      def set_text_leading(leading); end

      sig { params(mode: T.untyped).returns(T.untyped) }
      def set_text_rendering_mode(mode); end

      sig { params(rise: T.untyped).returns(T.untyped) }
      def set_text_rise(rise); end

      sig { params(word_spacing: T.untyped).returns(T.untyped) }
      def set_word_spacing(word_spacing); end

      sig { params(x: T.untyped, y: T.untyped).returns(T.untyped) }
      def move_text_position(x, y); end

      sig { params(x: T.untyped, y: T.untyped).returns(T.untyped) }
      def move_text_position_and_set_leading(x, y); end

      sig do
        params(
          a: T.untyped,
          b: T.untyped,
          c: T.untyped,
          d: T.untyped,
          e: T.untyped,
          f: T.untyped
        ).returns(T.untyped)
      end
      def set_text_matrix_and_text_line_matrix(a, b, c, d, e, f); end

      sig { returns(T.untyped) }
      def move_to_start_of_next_line; end

      sig { params(params: T.untyped).returns(T.untyped) }
      def show_text_with_positioning(params); end

      sig { params(str: T.untyped).returns(T.untyped) }
      def move_to_next_line_and_show_text(str); end

      sig { params(aw: T.untyped, ac: T.untyped, string: T.untyped).returns(T.untyped) }
      def set_spacing_next_line_show_text(aw, ac, string); end

      sig { params(label: T.untyped).returns(T.untyped) }
      def invoke_xobject(label); end

      sig { params(x: T.untyped, y: T.untyped).returns(T.untyped) }
      def ctm_transform(x, y); end

      sig { params(x: T.untyped, y: T.untyped).returns(T.untyped) }
      def trm_transform(x, y); end

      sig { returns(T.untyped) }
      def current_font; end

      sig { params(label: T.untyped).returns(T.untyped) }
      def find_font(label); end

      sig { params(label: T.untyped).returns(T.untyped) }
      def find_color_space(label); end

      sig { params(label: T.untyped).returns(T.untyped) }
      def find_xobject(label); end

      sig { returns(T.untyped) }
      def stack_depth; end

      sig { returns(T.untyped) }
      def clone_state; end

      sig { params(w0: T.untyped, tj: T.untyped, word_boundary: T.untyped).returns(T.untyped) }
      def process_glyph_displacement(w0, tj, word_boundary); end

      sig { returns(T.untyped) }
      def text_rendering_matrix; end

      sig { returns(T.untyped) }
      def ctm; end

      sig { returns(T.untyped) }
      def state; end

      sig { params(raw_fonts: T.untyped).returns(T.untyped) }
      def build_fonts(raw_fonts); end

      sig { returns(T.untyped) }
      def identity_matrix; end
    end

    class PageTextReceiver
      extend Forwardable
      SPACE = " "

      sig { returns(T.untyped) }
      attr_reader :state

      sig { returns(T.untyped) }
      attr_reader :options

      sig { params(page: T.untyped).returns(T.untyped) }
      def page=(page); end

      sig { returns(T.untyped) }
      def content; end

      sig { params(string: String).void }
      def show_text(string); end

      sig { params(params: T::Array[T.untyped]).void }
      def show_text_with_positioning(params); end

      sig { params(str: String).void }
      def move_to_next_line_and_show_text(str); end

      sig { params(opts: T::Hash[Symbol, T.untyped]).returns(T::Array[PDF::Reader::TextRun]) }
      def runs(opts = {}); end

      sig { params(aw: Numeric, ac: Numeric, string: String).void }
      def set_spacing_next_line_show_text(aw, ac, string); end

      sig { params(label: T.untyped).returns(T.untyped) }
      def invoke_xobject(label); end

      sig { params(string: String).void }
      def internal_show_text(string); end

      sig { params(x: T.untyped, y: T.untyped).returns(T.untyped) }
      def apply_rotation(x, y); end
    end

    class PagesStrategy
      OPERATORS = T.let(T.unsafe(nil), T::Hash[String, Symbol])
    end

    class Parser
      sig { params(buffer: PDF::Reader::Buffer, objects: T.nilable(PDF::Reader::ObjectHash)).void }
      def initialize(buffer, objects=nil); end

      sig {
        params(
          operators: T::Hash[T.any(String, PDF::Reader::Token), Symbol]
        ).returns(
          T.any(PDF::Reader::Reference, PDF::Reader::Token, Numeric, String, Symbol, T::Array[T.untyped], T::Hash[T.untyped, T.untyped], NilClass)
        )
      }
      def parse_token(operators={}); end

      sig {
        params(
         id: Integer,
         gen: Integer
        ).returns(
          T.any(PDF::Reader::Reference, PDF::Reader::Token, PDF::Reader::Stream, Numeric, String, Symbol, T::Array[T.untyped], T::Hash[T.untyped, T.untyped], NilClass)
        )
      }
      def object(id, gen); end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def dictionary; end

      sig { returns(Symbol) }
      def pdf_name; end

      sig { returns(T::Array[T.untyped]) }
      def array; end

      sig { returns(String) }
      def hex_string; end

      sig { returns(String) }
      def string; end

      sig { params(dict: T::Hash[Symbol, T.untyped]).returns(PDF::Reader::Stream) }
      def stream(dict); end
    end

    class Point
      sig do
        params(
          x: Numeric,
          y: Numeric,
        ).void
      end
      def initialize(x, y)
        @x = T.let(T.unsafe(nil), Numeric)
        @y = T.let(T.unsafe(nil), Numeric)
      end

      sig { returns(Numeric) }
      def x; end

      sig { returns(Numeric) }
      def y; end

      sig { params(other: PDF::Reader::Point).returns(T::Boolean) }
      def ==(other); end

    end

    class PrintReceiver
      sig { returns(T.untyped) }
      attr_accessor :callbacks

      sig { void }
      def initialize; end

      sig { params(meth: T.untyped).returns(T.untyped) }
      def respond_to?(meth); end

      sig { params(methodname: T.untyped, args: T.untyped).returns(T.untyped) }
      def method_missing(methodname, *args); end
    end

    class Rc4SecurityHandler
      sig { params(key: String).void }
      def initialize(key)
        @encrypt_key = T.let(T.unsafe(nil), String)
      end

      sig { params(buf: T.untyped, ref: T.untyped).returns(T.untyped) }
      def decrypt(buf, ref); end
    end

    class Rectangle

      sig { params(arr: T::Array[Numeric]).returns(PDF::Reader::Rectangle) }
      def self.from_array(arr); end

      sig do
        params(
          x1: Numeric,
          y1: Numeric,
          x2: Numeric,
          y2: Numeric
        ).void
      end

      def initialize(x1, y1, x2, y2)
        @bottom_left = T.let(T.unsafe(nil), PDF::Reader::Point)
        @bottom_right = T.let(T.unsafe(nil), PDF::Reader::Point)
        @top_left = T.let(T.unsafe(nil), PDF::Reader::Point)
        @top_right = T.let(T.unsafe(nil), PDF::Reader::Point)
      end

      sig { returns(PDF::Reader::Point) }
      def bottom_left; end

      sig { returns(PDF::Reader::Point) }
      def bottom_right; end

      sig { returns(PDF::Reader::Point) }
      def top_left; end

      sig { returns(PDF::Reader::Point) }
      def top_right; end

      sig { returns(Numeric) }
      def height; end

      sig { returns(Numeric) }
      def width; end

      sig { returns(T::Array[Numeric]) }
      def to_a; end

      sig { params(degrees: Integer).void }
      def apply_rotation(degrees); end

      sig { params(point: PDF::Reader::Point).void }
      def contains?(point); end

      sig { params(other: PDF::Reader::Rectangle).void }
      def ==(other); end

      sig { params(x1: Numeric, y1: Numeric, x2: Numeric, y2: Numeric).void }
      def set_corners(x1, y1, x2, y2); end
    end

    class Reference
      sig { returns(Integer) }
      attr_reader :id

      sig { returns(Integer) }
      attr_reader :gen

      sig { params(id: Integer, gen: Integer).void }
      def initialize(id, gen)
        @id = T.let(T.unsafe(nil), Integer)
        @gen = T.let(T.unsafe(nil), Integer)
      end

      sig { returns(T::Array[PDF::Reader::Reference]) }
      def to_a; end

      sig { returns(Integer) }
      def to_i; end

      sig { params(obj: Object).returns(T::Boolean) }
      def ==(obj); end

      sig { returns(Integer) }
      def hash; end
    end

    class RegisterReceiver
      sig { returns(T.untyped) }
      attr_accessor :callbacks

      sig { void }
      def initialize; end

      sig { params(meth: T.untyped).returns(T.untyped) }
      def respond_to?(meth); end

      sig { params(methodname: T.untyped, args: T.untyped).returns(T.untyped) }
      def method_missing(methodname, *args); end

      sig { params(methodname: T.untyped).returns(T.untyped) }
      def count(methodname); end

      sig { params(methodname: T.untyped).returns(T.untyped) }
      def all(methodname); end

      sig { params(methodname: T.untyped).returns(T.untyped) }
      def all_args(methodname); end

      sig { params(methodname: T.untyped).returns(T.untyped) }
      def first_occurance_of(methodname); end

      sig { params(methodname: T.untyped).returns(T.untyped) }
      def final_occurance_of(methodname); end

      sig { params(methods: T.untyped).returns(T.untyped) }
      def series(*methods); end
    end

    class Resources

      sig { params(objects: PDF::Reader::ObjectHash, resources: T::Hash[T.untyped, T.untyped]).void }
      def initialize(objects, resources)
        @objects = T.let(T.unsafe(nil), PDF::Reader::ObjectHash)
        @resources = T.let(T.unsafe(nil), T::Hash[Symbol, T.untyped])
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def color_spaces; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def fonts; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def graphic_states; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def patterns; end

      sig { returns(T::Array[Symbol]) }
      def procedure_sets; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def properties; end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def shadings; end

      sig { returns(T::Hash[Symbol, PDF::Reader::Stream]) }
      def xobjects; end
    end

    class SecurityHandlerFactory
      sig { params(encrypt: T.untyped, doc_id: T.untyped, password: T.untyped).returns(T.untyped) }
      def self.build(encrypt, doc_id, password); end

      sig { params(encrypt: T.untyped, doc_id: T.untyped, password: T.untyped).returns(T.untyped) }
      def self.build_standard_handler(encrypt, doc_id, password); end

      sig { params(encrypt: T.untyped, doc_id: T.untyped, password: T.untyped).returns(T.untyped) }
      def self.build_v5_handler(encrypt, doc_id, password); end

      sig { params(encrypt: T.untyped).returns(T.untyped) }
      def self.standard?(encrypt); end

      sig { params(encrypt: T.untyped).returns(T.untyped) }
      def self.standard_v5?(encrypt); end
    end

    class StandardKeyBuilder
      PassPadBytes = [ 0x28, 0xbf, 0x4e, 0x5e, 0x4e, 0x75, 0x8a, 0x41,
                     0x64, 0x00, 0x4e, 0x56, 0xff, 0xfa, 0x01, 0x08,
                     0x2e, 0x2e, 0x00, 0xb6, 0xd0, 0x68, 0x3e, 0x80,
                     0x2f, 0x0c, 0xa9, 0xfe, 0x64, 0x53, 0x69, 0x7a ]

      sig { params(opts: T::Hash[Symbol, T.untyped]).void }
      def initialize(opts = {}); end

      sig { params(pass: String).returns(String) }
      def key(pass); end

      sig { params(p: T.untyped).returns(T.untyped) }
      def pad_pass(p = ""); end

      sig { params(buf: T.untyped, int: T.untyped).returns(T.untyped) }
      def xor_each_byte(buf, int); end

      sig { params(pass: T.untyped).returns(T.untyped) }
      def auth_owner_pass(pass); end

      sig { params(pass: T.untyped).returns(T.untyped) }
      def auth_user_pass(pass); end

      sig { params(user_pass: T.untyped).returns(T.untyped) }
      def make_file_key(user_pass); end
    end

    class Stream
      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_accessor :hash

      sig { returns(String) }
      attr_accessor :data

      sig { params(hash: T::Hash[Symbol, T.untyped], data: String).void }
      def initialize(hash, data)
        @hash = T.let(T.unsafe(nil), T::Hash[Symbol, T.untyped])
        @data = T.let(T.unsafe(nil), String)
        @udata = T.let(T.unsafe(nil), T.nilable(String))
      end

      sig { returns(String) }
      def unfiltered_data; end
    end

    class SynchronizedCache
      sig { void }
      def initialize
        @cache = T.let(T.unsafe(nil), T::Hash[Object, T.untyped])
        @mutex = T.let(T.unsafe(nil), Mutex)
      end

      sig { params(key: Object).returns(T.untyped) }
      def [](key); end

      sig { params(key: Object, value: T.nilable(Object)).returns(T.untyped) }
      def []=(key, value); end
    end

    class TextRun
      include Comparable

      sig { returns(Numeric) }
      attr_reader :width

      sig { returns(Numeric) }
      attr_reader :font_size

      sig { returns(String) }
      attr_reader :text

      sig { returns(PDF::Reader::Point) }
      attr_reader :origin

      sig do
        params(
          x: Numeric,
          y: Numeric,
          width: Numeric,
          font_size: Numeric,
          text: String
        ).void
      end
      def initialize(x, y, width, font_size, text)
        @origin = T.let(T.unsafe(nil), PDF::Reader::Point)
        @width = T.let(T.unsafe(nil), Numeric)
        @font_size = T.let(T.unsafe(nil), Numeric)
        @text = T.let(T.unsafe(nil), String)
        @endx = T.let(T.unsafe(nil), T.nilable(Numeric))
        @endy = T.let(T.unsafe(nil), T.nilable(Numeric))
        @mergable_range = T.let(T.unsafe(nil), T.nilable(T::Range[Numeric]))
      end

      sig { params(other: T.untyped).returns(T.untyped) }
      def <=>(other); end

      sig { returns(Numeric) }
      def endx; end

      sig { returns(Numeric) }
      def endy; end

      sig { returns(Numeric) }
      def x; end

      sig { returns(Numeric) }
      def y; end

      sig { returns(Numeric) }
      def mean_character_width; end

      sig { params(other: PDF::Reader::TextRun).returns(T::Boolean) }
      def mergable?(other); end

      sig { params(other: PDF::Reader::TextRun).returns(PDF::Reader::TextRun) }
      def +(other); end

      sig { returns(String) }
      def inspect; end

      sig { params(other_run: T.untyped).returns(T::Boolean) }
      def intersect?(other_run); end

      sig { params(other_run: T.untyped).returns(Numeric) }
      def intersection_area_percent(other_run); end

      sig { returns(Numeric) }
      def area; end

      sig { returns(T::Range[Numeric]) }
      def mergable_range; end

      sig { returns(Numeric) }
      def character_count; end
    end

    class Token < String
      sig { params(val: T.untyped).void }
      def initialize(val); end
    end

    class TransformationMatrix
      sig { returns(Numeric) }
      attr_reader :a

      sig { returns(Numeric) }
      attr_reader :b

      sig { returns(Numeric) }
      attr_reader :c

      sig { returns(Numeric) }
      attr_reader :d

      sig { returns(Numeric) }
      attr_reader :e

      sig { returns(Numeric) }
      attr_reader :f

      sig do
        params(
          a: Numeric,
          b: Numeric,
          c: Numeric,
          d: Numeric,
          e: Numeric,
          f: Numeric
        ).void
      end
      def initialize(a, b, c, d, e, f)
        @a = T.let(T.unsafe(nil), Numeric)
        @b = T.let(T.unsafe(nil), Numeric)
        @c = T.let(T.unsafe(nil), Numeric)
        @d = T.let(T.unsafe(nil), Numeric)
        @e = T.let(T.unsafe(nil), Numeric)
        @f = T.let(T.unsafe(nil), Numeric)
      end

      sig { returns(String) }
      def inspect; end

      sig { returns(T::Array[Numeric]) }
      def to_a; end

      sig do
        params(
          a: Numeric,
          b: Numeric,
          c: Numeric,
          d: Numeric,
          e: Numeric,
          f: Numeric
        ).returns(PDF::Reader::TransformationMatrix)
      end
      def multiply!(a, b, c, d, e, f); end

      sig { params(e2: Numeric).void }
      def horizontal_displacement_multiply!(e2); end

      sig do
        params(
          a2: Numeric,
          b2: Numeric,
          c2: Numeric,
          d2: Numeric,
          e2: Numeric,
          f2: Numeric
        ).void
      end
      def horizontal_displacement_multiply_reversed!(a2, b2, c2, d2, e2, f2); end

      sig do
        params(
          a2: Numeric,
          b2: Numeric,
          c2: Numeric,
          d2: Numeric,
          e2: Numeric,
          f2: Numeric
        ).void
      end
      def xy_scaling_multiply!(a2, b2, c2, d2, e2, f2); end

      sig do
        params(
          a2: Numeric,
          b2: Numeric,
          c2: Numeric,
          d2: Numeric,
          e2: Numeric,
          f2: Numeric
        ).void
      end
      def xy_scaling_multiply_reversed!(a2, b2, c2, d2, e2, f2); end

      sig do
        params(
          a2: Numeric,
          b2: Numeric,
          c2: Numeric,
          d2: Numeric,
          e2: Numeric,
          f2: Numeric
        ).void
      end
      def regular_multiply!(a2, b2, c2, d2, e2, f2); end

      sig do
        params(
          a2: Numeric,
          b2: Numeric,
          c2: Numeric,
          d2: Numeric,
          e2: Numeric,
          f2: Numeric
        ).void
      end
      def faster_multiply!(a2, b2, c2, d2, e2, f2); end
    end

    class TypeCheck

      sig { params(obj: T.untyped).returns(Integer) }
      def self.cast_to_int!(obj); end

      sig { params(obj: T.untyped).returns(Numeric) }
      def self.cast_to_numeric!(obj); end

      sig { params(string: T.untyped).returns(String) }
      def self.cast_to_string!(string); end

      sig { params(obj: T.untyped).returns(T.nilable(Symbol)) }
      def self.cast_to_symbol(obj); end

      sig { params(obj: T.untyped).returns(Symbol) }
      def self.cast_to_symbol!(obj); end

      sig { params(obj: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def self.cast_to_pdf_dict!(obj); end

      sig { params(obj: T.untyped).returns(T::Hash[Symbol, PDF::Reader::Stream]) }
      def self.cast_to_pdf_dict_with_stream_values!(obj); end
    end

    class ValidatingReceiver
      sig { params(wrapped: T.untyped).void }
      def initialize(wrapped)
        @wrapped = T.let(T.unsafe(nil), T.untyped)
      end

      sig { params(page: PDF::Reader::Page).void }
      def page=(page); end

      sig { params(args: T.untyped).void }
      def save_graphics_state(*args); end

      sig { params(args: T.untyped).void }
      def restore_graphics_state(*args); end

      sig { params(args: T.untyped).void }
      def concatenate_matrix(*args); end

      sig { params(args: T.untyped).void }
      def begin_text_object(*args); end

      sig { params(args: T.untyped).void }
      def end_text_object(*args); end

      sig { params(args: T.untyped).void }
      def set_character_spacing(*args); end

      sig { params(args: T.untyped).void }
      def set_horizontal_text_scaling(*args); end

      sig { params(args: T.untyped).void }
      def set_text_font_and_size(*args); end

      sig { params(args: T.untyped).void }
      def set_text_leading(*args); end

      sig { params(args: T.untyped).void }
      def set_text_rendering_mode(*args); end

      sig { params(args: T.untyped).void }
      def set_text_rise(*args); end

      sig { params(args: T.untyped).void }
      def set_word_spacing(*args); end

      sig { params(args: T.untyped).void }
      def move_text_position(*args); end

      sig { params(args: T.untyped).void }
      def move_text_position_and_set_leading(*args); end

      sig { params(args: T.untyped).void }
      def set_text_matrix_and_text_line_matrix(*args); end

      sig { params(args: T.untyped).void }
      def move_to_start_of_next_line(*args); end

      sig { params(args: T.untyped).void }
      def show_text(*args); end

      sig { params(args: T.untyped).void }
      def show_text_with_positioning(*args); end

      sig { params(args: T.untyped).void }
      def move_to_next_line_and_show_text(*args); end

      sig { params(args: T.untyped).void }
      def set_spacing_next_line_show_text(*args); end

      sig { params(args: T.untyped).void }
      def invoke_xobject(*args); end

      sig { params(args: T.untyped).void }
      def begin_inline_image(*args); end

      sig { params(args: T.untyped).void }
      def begin_inline_image_data(*args); end

      sig { params(args: T.untyped).void }
      def end_inline_image(*args); end

      sig { params(meth: T.untyped).returns(T::Boolean) }
      def respond_to?(meth); end

      sig { params(methodname: Symbol, args: T.untyped).void }
      def method_missing(methodname, *args); end

      sig { params(methodname: T.untyped, args: T.untyped).void }
      def call_wrapped(methodname, *args); end
    end

    class UnimplementedSecurityHandler
      sig { params(encrypt: T.untyped).returns(T.untyped) }
      def self.supports?(encrypt); end

      sig { params(buf: T.untyped, ref: T.untyped).returns(T.untyped) }
      def decrypt(buf, ref); end
    end

    class XRef
      include Enumerable
      extend T::Generic # Provides `type_member` helper

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :trailer

      sig { params(io: T.any(IO, Tempfile, StringIO)).void }
      def initialize(io)
        @io = T.let(T.unsafe(nil), T.any(IO, Tempfile, StringIO))
        @junk_offset = T.let(T.unsafe(nil), Integer)
        @xref = T.let(T.unsafe(nil), T::Hash[Integer, T::Hash[Integer, Integer]])
        @trailer = T.let(T.unsafe(nil), T::Hash[Symbol, T.untyped])
      end

      sig { returns(T.untyped) }
      def size; end

      sig { params(ref: T.untyped).returns(T.untyped) }
      def [](ref); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each(&block); end

      sig { params(offset: T.untyped).returns(T.untyped) }
      def load_offsets(offset = nil); end

      sig { params(buf: T.untyped).returns(T.untyped) }
      def load_xref_table(buf); end

      sig { params(stream: T.untyped).returns(T.untyped) }
      def load_xref_stream(stream); end

      sig { params(bytes: T.untyped).returns(T.untyped) }
      def unpack_bytes(bytes); end

      sig { params(offset: T.untyped).returns(T.untyped) }
      def new_buffer(offset = 0); end

      sig { params(id: T.untyped, gen: T.untyped, offset: T.untyped).returns(T.untyped) }
      def store(id, gen, offset); end

      sig { params(io: T.untyped).returns(T.untyped) }
      def calc_junk_offset(io); end
    end

    class ZeroWidthRunsFilter
      sig { params(runs: T::Array[PDF::Reader::TextRun]).returns(T::Array[PDF::Reader::TextRun]) }
      def self.exclude_zero_width_runs(runs); end
    end

    module Filter
      sig { params(name: Symbol, options: T::Hash[T.untyped, T.untyped]).returns(T.untyped) }
      def self.with(name, options = {}); end

      class Ascii85
        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: String).returns(String) }
        def filter(data); end
      end

      class AsciiHex
        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: String).returns(String) }
        def filter(data); end
      end

      class Depredict
        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: String).returns(String) }
        def filter(data); end

        sig { params(data: T.untyped).returns(T.untyped) }
        def tiff_depredict(data); end

        sig { params(data: T.untyped).returns(T.untyped) }
        def png_depredict(data); end
      end

      class Flate
        ZLIB_AUTO_DETECT_ZLIB_OR_GZIP = 47
        ZLIB_RAW_DEFLATE = -15

        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: String).returns(String) }
        def filter(data); end

        sig { params(data: T.untyped).returns(T.untyped) }
        def zlib_inflate(data); end
      end

      class Lzw
        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: String).returns(String) }
        def filter(data); end
      end

      class Null
        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: T.untyped).returns(T.untyped) }
        def filter(data); end
      end

      class RunLength
        sig { params(options: T::Hash[T.untyped, T.untyped]).void }
        def initialize(options = {})
          @options = T.let(T.unsafe(nil), T::Hash[T.untyped, T.untyped])
        end

        sig { params(data: String).returns(String) }
        def filter(data); end
      end
    end

    module WidthCalculator
      class BuiltIn
        BUILTINS = T.let(T.unsafe(nil), T::Array[Symbol])

        @@all_metrics = T.let(T.unsafe(nil), T.nilable(PDF::Reader::SynchronizedCache))

        sig { params(font: PDF::Reader::Font).void }
        def initialize(font)
          @font = T.let(T.unsafe(nil), PDF::Reader::Font)
          @metrics = T.let(T.unsafe(nil), AFM::Font)
        end

        sig { params(code_point: T.nilable(Integer)).returns(Numeric) }
        def glyph_width(code_point); end

        sig { params(code_point: Integer).returns(T::Boolean) }
        def control_character?(code_point); end

        sig { params(font_name: T.nilable(Symbol)).returns(String) }
        def extract_basefont(font_name); end
      end

      class Composite
        sig { params(font: PDF::Reader::Font).void }
        def initialize(font)
          @font = T.let(T.unsafe(nil), PDF::Reader::Font)
          @widths = T.let(T.unsafe(nil), PDF::Reader::CidWidths)
        end

        sig { params(code_point: T.nilable(Integer)).returns(Numeric) }
        def glyph_width(code_point); end
      end

      class TrueType
        sig { params(font: PDF::Reader::Font).void }
        def initialize(font)
          @font = T.let(T.unsafe(nil), PDF::Reader::Font)
          @missing_width = T.let(T.unsafe(nil), Numeric)
        end

        sig { params(code_point: T.nilable(Integer)).returns(Numeric) }
        def glyph_width(code_point); end

        sig { params(code_point: Integer).returns(T.nilable(Numeric)) }
        def glyph_width_from_font(code_point); end

        sig { params(code_point: Integer).returns(T.nilable(Numeric)) }
        def glyph_width_from_descriptor(code_point); end
      end

      class TypeOneOrThree
        sig { params(font: PDF::Reader::Font).void }
        def initialize(font)
          @font = T.let(T.unsafe(nil), PDF::Reader::Font)
          @missing_width = T.let(T.unsafe(nil), Numeric)
        end

        sig { params(code_point: T.nilable(Integer)).returns(Numeric) }
        def glyph_width(code_point); end
      end

      class TypeZero
        sig { params(font: PDF::Reader::Font).void }
        def initialize(font)
          @font = T.let(T.unsafe(nil), PDF::Reader::Font)
        end

        sig { params(code_point: T.nilable(Integer)).returns(Numeric) }
        def glyph_width(code_point); end
      end
    end
  end
end
