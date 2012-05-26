# coding: utf-8

require 'parslet'

module PDF
  class Reader
    class Transform < Parslet::Transform
      rule(:string_literal => simple(:value)) { value.to_s }
      rule(:string_literal => subtree(:value)) {
        if value.is_a?(String)
          value
        elsif value.is_a?(Array) && value.size > 0
          Transform.new.apply(value.first)
        else
          ""
        end
      }

      rule(:string_hex => simple(:value)) {
        value << "0" unless value.size % 2 == 0
        value.to_s.gsub(/[^A-F0-9]/i,"").scan(/../).map { |i| i.hex.chr }.join
      }

      rule(:name => simple(:value)) {
        value.to_s.scan(/#([A-Fa-f0-9]{2})/).each do |find|
          replace = find[0].hex.chr
          value.gsub!("#"+find[0], replace)
        end
        value.to_sym
      }

      rule(:float => simple(:value)) { value.to_f }

      rule(:integer => simple(:value)) { value.to_i }

      rule(:boolean => simple(:value)) { value.to_s == "true" }

      rule(:null => simple(:value)) { nil }

      rule(:array => subtree(:contents)) { Transform.new.apply(contents) }

      rule(:dict => subtree(:contents)) {
        ::Hash[*Transform.new.apply(contents)]
      }

      rule(:indirect => simple(:value)) { value.to_s }

      rule(:keyword => simple(:value)) { value.to_s }

      rule(:op => simple(:value)) { Token.new(value.to_s) }
    end
  end
end
