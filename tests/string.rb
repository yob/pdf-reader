#!/usr/bin/env ruby
################################################################################
#
# Copyright (C) 2006 Peter J Jones (pjones@pmade.com)
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
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'stringio'
require 'test/unit'
require 'pdf/reader'
################################################################################
class TestString < Test::Unit::TestCase
  ################################################################################
  def assert_parse (l, r)
    assert_equal(l, PDF::Reader::Parser.new(PDF::Reader::Buffer.new(sio = StringIO.new(r)), nil).string)
  end
  ################################################################################
  def test_parsing
    assert_parse("this is a string", "this is a string)")
    assert_parse("this \n is a string", "this \\n is a string)")
    assert_parse("x \t x", "x \\t x)")
    assert_parse("x A x", "x \\101 x)")
    assert_parse("x ( x", "x \\( x)")
    assert_parse("(x)", "(x))")
    assert_parse("x\nx x", <<EOT)
x
x \
x)
EOT
  end
  ################################################################################
end
################################################################################
