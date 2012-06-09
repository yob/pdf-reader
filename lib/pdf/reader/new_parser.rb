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
        elements[1].text_value.to_sym
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
        elements[1].text_value
      end
    end

    class NewParser
      Treetop.load(File.join(File.dirname(__FILE__), 'pdf.treetop'))
      @@parser = PdfParser.new

      def self.parse(data)
        # Pass the data over to the parser instance
        tree = @@parser.parse(data, root: :body)

        # If the AST is nil then there was an error during parsing
        # we need to report a simple error message to help the user
        if tree.nil?
          raise Exception, "Parse error at offset: #{@@parser.index}"
        end

        tree.elements.select { |obj|
          obj.respond_to?(:to_ruby)
        }.map(&:to_ruby)
      end
    end
  end
end
