# coding: utf-8

require 'treetop'

module PDF
  class Reader
    class ArrayNode < Treetop::Runtime::SyntaxNode
      def to_ruby
        elements[1].elements.select { |obj|
          obj.respond_to?(:to_ruby)
        }.map(&:to_ruby)
      end
    end

    class DictNode < Treetop::Runtime::SyntaxNode
      def to_ruby
        ret = {}
        entries = elements[1].elements.map(&:elements).flatten.select { |node|
          node.elements.any? { |e| e.respond_to?(:to_ruby)}
        }
        entries.each do |entry|
          interesting_nodes = entry.elements.select { |e| e.respond_to?(:to_ruby) }
          ret[interesting_nodes.first.to_ruby] = interesting_nodes.last.to_ruby
        end
        ret
      end
    end

    class Integer < Treetop::Runtime::SyntaxNode
      def to_ruby
        text_value.to_i
      end
    end

    class Float < Treetop::Runtime::SyntaxNode
      def to_ruby
        text_value.to_f
      end
    end

    class Name < Treetop::Runtime::SyntaxNode
      def to_ruby
        elements[1].text_value.gsub(/#\h\h/) { |match|
          match[1, 2].hex.chr
        }.to_sym
      end
    end

    class BooleanNode < Treetop::Runtime::SyntaxNode
      def to_ruby
        text_value == "true"
      end
    end

    class NullNode < Treetop::Runtime::SyntaxNode
      def to_ruby
        nil
      end
    end

    class HexString < Treetop::Runtime::SyntaxNode
      def to_ruby
        elements[1].text_value.scan(/../).map { |i| i.hex.chr }.join
      end
    end

    class LiteralString < Treetop::Runtime::SyntaxNode
      def to_ruby
        elements[1].text_value.
          gsub("\\n","\x0A").  # \n becomes New Line
          gsub("\\r","\x0D").  # \r becomes Carriage Return
          gsub("\\t","\x09").  # \t becomes Horizontal Tab
          gsub("\\b","\x08").  # \b becomes Backspace
          #gsub("\\b","\x08"). # \f becomes Form Feed
          gsub("\\(","\x28").  # \( becomes Left Paren
          gsub("\\)","\x29").  # \\ becomes Right Paren
          gsub("\\\\","\x5C"). # \\ becomes \
          gsub(/\\([0-7]){3}/) { |m| m[1,3].oct.chr }.  # \ddd is an octal char
          gsub(/\\([0-7]){2}/) { |m| m[1,2].oct.chr }.  # \dd  is an octal char
          gsub(/\\([0-7]){1}/) { |m| m[1,1].oct.chr }   # \d   is an octal char
      end
    end

    class Operator < Treetop::Runtime::SyntaxNode
      def to_ruby
        Token.new(text_value)
      end
    end

    class NewParser
      Treetop.load(File.join(File.dirname(__FILE__), 'pdf.treetop'))

      def initialize(data)
        @data = data
        @parser = PdfParser.new
        @parser.consume_all_input = false
        @parser.root = :content_stream
        @pos = 0
        @tokens = []
      end

      def next_token
        prepare_tokens if @tokens.size <= 3
        @tokens.shift
      end

      def all_tokens
        prepare_tokens if @tokens.size <= 3
        @tokens
      end

      private

      def prepare_tokens
        tree = @parser.parse(@data, index: @pos)
        if tree
          @tokens += tree.elements.select { |obj|
            obj.respond_to?(:to_ruby)
          }.map(&:to_ruby)
        else
          # If the AST is nil then there was an error during parsing
          # we need to report a simple error message to help the user
          raise Exception, "Parse error at offset: #{@parser.index}"
        end
        @pos = @parser.index
      end

    end
  end
end
