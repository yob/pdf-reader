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

      rule(:content_stream) { ( base_object | operator | space ).repeat }

      rule(:base_object) { ( string_literal | string_hex | array | dict | name | boolean_t | boolean_f | null | indirect | float | integer ) }

      rule(:string_literal_content) {
        str('\(') | str('\)') | match["^()"]
      }

      rule(:string_literal) {
        str("(") >> (string_literal_content | string_literal).repeat.as(:string_literal) >> str(")")
      }

      rule(:string_hex)     { str("<") >> (hex_char | space).repeat(1).as(:string_hex) >> str(">") }

      rule(:hex_char)       { lower_hex_char | upper_hex_char | single_digit }
      rule(:lower_hex_char) { str("a") | str("b") | str("c") |  str("d") |  str("e") |  str("f")  }
      rule(:upper_hex_char) { str("A") | str("B") | str("C") |  str("D") |  str("E") |  str("F")  }

      rule(:array)          { str("[") >> (base_object | space).repeat.as(:array) >> str("]") }

      rule(:dict)           { str("<<") >> (base_object |space).repeat.as(:dict) >> str(">>") }

      rule(:name)           { str('/') >> regular.repeat(1).as(:name) }

      rule(:float)          { (sign.maybe >> single_digit.repeat(1) >> str('.') >> single_digit.repeat(1) ).as(:float) }

      rule(:integer)        { (sign.maybe >> single_digit.repeat(1)).as(:integer) }

      rule(:sign)           { str("+") | str("-") }

      rule(:single_digit)   { (str("0") | str("1") | str("2") | str("3") | str("4") | str("5") | str("6") | str("7") | str("8") | str("9"))}

      rule(:indirect)       { (single_digit.repeat(1) >> space >> single_digit.repeat(1) >> space >> str("R")).as(:indirect) }

      rule(:boolean_t)      { str("true").as(:boolean)}

      rule(:boolean_f)      { str("false").as(:boolean)}

      rule(:null)           { str('null').as(:null) }

      rule(:operator)   { match('[^\(\)<>\[\]{}/%\x00\x09\x0A\x0C\x0D\x20]').repeat(1,3).as(:op)}

      #rule(:keyword)        { (str('obj') | str('endobj') | str('stream') | str('endstream')).as(:keyword)}

      root(:content_stream)
    end
  end
end
