# coding: utf-8

require 'parslet'

module PDF
  class Reader
    class NewParser < Parslet::Parser

      rule(:space)      { (str("\x00") | str("\x09") | str("\x0A") | str("\x0C") | str("\x0D") | str("\x20")).repeat(1) }
      rule(:space?)     { space.maybe }

      # match any regular byte, basically anything that isn't whitespace or a
      # delimiter
      rule(:regular)   { match('[^\(\)<>\[\]{}/%\x00\x09\x0A\x0C\x0D\x20]')}

      rule(:doc) { ( string_literal | string_hex | array | dict | name | boolean | null | keyword | indirect | float | integer | space ).repeat }

      rule(:string_literal_content) {
        str('\(') | str('\)') | match["^()"]
      }

      rule(:string_literal) {
        str("(") >> (string_literal_content | string_literal).repeat.as(:string_literal) >> str(")")
      }

      rule(:string_hex)     { str("<") >> (match('[A-Fa-f0-9]') | space).repeat(1).as(:string_hex) >> str(">") }

      rule(:array)          { str("[") >> doc.as(:array) >> str("]") }

      rule(:dict)           { str("<<") >> doc.as(:dict) >> str(">>") }

      rule(:name)           { str('/') >> regular.repeat(1).as(:name) }

      rule(:float)          { (match('[\+\-]').maybe >> match('[0-9]').repeat(1) >> str('.') >> match('[0-9]').repeat(1) ).as(:float) }

      rule(:integer)        { (match('[\+\-]').maybe >> match('[0-9]').repeat(1)).as(:integer) }

      rule(:indirect)       { (match('[0-9]').repeat(1) >> space >> match('[0-9]').repeat(1) >> space >> str("R")).as(:indirect) }

      rule(:boolean)        { (str("true") | str("false")).as(:boolean)}

      rule(:null)           { str('null').as(:null) }

      rule(:keyword)        { (str('obj') | str('endobj') | str('stream') | str('endstream')).as(:keyword)}

      root(:doc)
    end
  end
end
