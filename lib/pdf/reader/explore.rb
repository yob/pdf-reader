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
require 'pathname'
################################################################################
class PDF::Reader
  ################################################################################
  class Explore
    ################################################################################
    def self.file (name)
      PDF::Reader.new.parse(File.open(name), self)
    end
    ################################################################################
    def initialize (receiver, xref)
      @xref = xref
      @pwd  = '/'
    end
    ################################################################################
    def document (root)
      @root = root
      self
    end
    ################################################################################
    def output_parent (obj)
      case obj
      when Hash
        obj.each do |k,v| 
          print "#{k}"; output_child(v); print "\n"
          Explore::const_set(k, k) if !Explore.const_defined?(k)
        end
      when Array
        obj.each_with_index {|o, i| print "#{i}: "; output_child(o); print "\n"}
      else
        output_child(obj)
        print "\n"
      end
    end
    ################################################################################
    def output_child (obj)
      print ": #{obj.class}"

      case obj
      when Float
        print ": #{obj}"
      when String
        print ": #{obj[0, 20].sub(/\n/, ' ')}"
      end
    end
    ################################################################################
    def cd (path)
      path = path.to_s

      if path[0,1] == "/"
        @pwd = path
      else
        @pwd = Pathname.new(@pwd + '/' + path).cleanpath.to_s
      end
    end
    ################################################################################
    def pwd
      @pwd
    end
    ################################################################################
    def ls (entry = nil)
      parts = @pwd.split('/')
      obj   = @root

      parts.shift if parts[0] == ""
      parts.push(entry) if entry

      parts.each do |p|
        case obj
        when Hash
          unless obj.has_key?(p)
            puts "invalid path at #{p}"
            return
          end
          obj = obj[p]

        when Array
          obj = obj[p.to_i]
        end

        obj = @xref.object(obj) if obj.kind_of?(Reference)
      end

      output_parent(obj)
      "#{@pwd}: #{obj.class}"
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
