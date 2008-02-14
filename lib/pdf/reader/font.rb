################################################################################
#
# Copyright (C) 2008 James Healy (jimmy@deefa.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

class PDF::Reader
  class Font
    attr_accessor :label, :subtype, :encoding, :descendantfonts, :tounicode
    attr_reader :basefont

    def basefont=(font)
      # setup a default encoding for the selected font. It can always be overridden
      # with encoding= if required
      case font
      when "Symbol" then 
        self.encoding = PDF::Reader::Encoding.factory("SymbolEncoding")
      when "ZapfDingbats" then 
        self.encoding = PDF::Reader::Encoding.factory("ZapfDingbatsEncoding")
      end
    end

    def to_utf8(params)
      raise UnsupportedFeatureError, "font encoding '#{encoding}' currently unsupported" if encoding.kind_of?(String)

      return params if encoding.nil?

      params.collect do |param|
        if param.class == Array
          self.to_utf8(param)
        elsif param.class == String
          encoding.to_utf8(param, tounicode)
        else
          param
        end
      end
    end
  end
end
