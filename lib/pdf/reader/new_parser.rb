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

      rule(:doc) { ( op | string_literal | string_hex | array | dict | name | boolean | null | keyword | indirect | float | integer | space ).repeat }

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

      rule(:op)             {
                              str("BDC").as(:op) |
                              str("BMC").as(:op) |
                              str("EMC").as(:op) |
                              str("SCN").as(:op) |
                              str("scn").as(:op) |
                              str("b*").as(:op)  |
                              str("B*").as(:op)  |
                              str("BI").as(:op)  |
                              str("BT").as(:op)  |
                              str("BX").as(:op)  |
                              str("cm").as(:op)  |
                              str("CS").as(:op)  |
                              str("cs").as(:op)  |
                              str("d0").as(:op)  |
                              str("d1").as(:op)  |
                              str("Do").as(:op)  |
                              str("DP").as(:op)  |
                              str("EI").as(:op)  |
                              str("ET").as(:op)  |
                              str("EX").as(:op)  |
                              str("f*").as(:op)  |
                              str("gs").as(:op)  |
                              str("ID").as(:op)  |
                              str("MP").as(:op)  |
                              str("re").as(:op)  |
                              str("RG").as(:op)  |
                              str("rg").as(:op)  |
                              str("ri").as(:op)  |
                              str("SC").as(:op)  |
                              str("sc").as(:op)  |
                              str("sh").as(:op)  |
                              str("T*").as(:op)  |
                              str("Tc").as(:op)  |
                              str("Td").as(:op)  |
                              str("TD").as(:op)  |
                              str("Tf").as(:op)  |
                              str("Tj").as(:op)  |
                              str("TJ").as(:op)  |
                              str("TL").as(:op)  |
                              str("Tm").as(:op)  |
                              str("Tr").as(:op)  |
                              str("Ts").as(:op)  |
                              str("Tw").as(:op)  |
                              str("Tz").as(:op)  |
                              str("W*").as(:op)  |
                              str("b").as(:op)   |
                              str("B").as(:op)   |
                              str("c").as(:op)   |
                              str("d").as(:op)   |
                              str("f").as(:op)   |
                              str("F").as(:op)   |
                              str("G").as(:op)   |
                              str("g").as(:op)   |
                              str("h").as(:op)   |
                              str("i").as(:op)   |
                              str("j").as(:op)   |
                              str("J").as(:op)   |
                              str("K").as(:op)   |
                              str("k").as(:op)   |
                              str("l").as(:op)   |
                              str("m").as(:op)   |
                              str("M").as(:op)   |
                              str("n").as(:op)   |
                              str("q").as(:op)   |
                              str("Q").as(:op)   |
                              str('q').as(:op)   |
                              str('Q').as(:op)   |
                              str("s").as(:op)   |
                              str("S").as(:op)   |
                              str("v").as(:op)   |
                              str("w").as(:op)   |
                              str("W").as(:op)   |
                              str("y").as(:op)   |
                              str("'").as(:op)   |
                              str('"').as(:op)
                            }

      rule(:keyword)        { (str('obj') | str('endobj') | str('stream') | str('endstream')).as(:keyword)}

      root(:doc)
    end
  end
end
