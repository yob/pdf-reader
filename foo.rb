require 'treetop'

module PDF
  class Reader
    class Token < Treetop::Runtime::SyntaxNode
      def to_ary
        [self.text_value]
      end
    end
  end
end

class Parser
  Treetop.load(File.join(File.dirname(__FILE__), 'pdf.treetop'))
  @@parser = PdfParser.new

  def self.parse(data)
    # Pass the data over to the parser instance
    tree = @@parser.parse(data)

    # If the AST is nil then there was an error during parsing
    # we need to report a simple error message to help the user
    if tree.nil?
      raise Exception, "Parse error at offset: #{@@parser.index}"
    end

    self.clean_tree(tree).elements.flatten
  end

  def self.clean_tree(root_node)
    return if root_node.elements.nil?

    root_node.elements.delete_if {|node| node.class.name == "Treetop::Runtime::SyntaxNode" }
    root_node.elements.each {|node| self.clean_tree(node) }
    root_node
  end

end

str = "(abc)"
result = Parser.parse(str)

p result
