################################################################################
#
# Copyright (C) 2011 Evan J Brunner (ejbrun@appittome.com)
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

  class Decrypt
    require 'digest/md5'
    require 'rc4'
    PassPadBytes = [ 0x28, 0xbf, 0x4e, 0x5e, 0x4e, 0x75, 0x8a, 0x41,
                     0x64, 0x00, 0x4e, 0x56, 0xff, 0xfa, 0x01, 0x08,
                     0x2e, 0x2e, 0x00, 0xb6, 0xd0, 0x68, 0x3e, 0x80,
                     0x2f, 0x0c, 0xa9, 0xfe, 0x64, 0x53, 0x69, 0x7a ]

    def self.makeFileKey( pass, secHandler )

      #if there's a password, pad it to 32 bytes, else, just use the padding.
      @buf  = padPass(pass)
      #add owner key
      @buf << secHandler.ownerKey
      #add permissions 1 byte at a time, in little-endian order
      (0..24).step(8){|e| @buf << (secHandler.permissions >> e & 0xFF)}
      #add the file ID
      @buf << secHandler.fileID
      #if revision > 4 then if encryptMetadata add 4 bytes of 0xFF else add 4 bytes of 0x00 
      if (secHandler.encRevision > 4)
        @buf << [ secHandler.encryptMetadata ? 0x0 : 0xFF ].pack('C')*4
      end
      md5 = Digest::MD5.new()
      md5 << @buf
      digest = md5.digest
      if (secHandler.encRevision > 2) then
        (0...50).each {|e|
          digest = Digest::MD5.digest(digest[(0...secHandler.keyLength)])
        }
      end
      digest
    end

    def self.authOwnerPass(pass, secHandler)
      #new md5 digest from password padded to 32 bytes
      md5 = Digest::MD5.digest(padPass(pass))
      if ( secHandler.encRevision > 2 ) then
        50.times { md5 = Digest::MD5.digest(md5) }
        keyBegins = md5[(0...secHandler.keyLength)]
        #first itteration decrypt ownerKey
        out = secHandler.ownerKey
        #RC4 keyed with (keyBegins XOR with itteration #) to decrypt previous out
        19.downto(0).each { |i| out=RC4.new(xorEachByte(keyBegins,i)).decrypt(out) }
      else #encRevision < 3
        out = RC4.new( md5[(0...5)] ).decrypt( secHandler.ownerKey )
      end
      authUserPass( out, secHandler )
    end

    def self.authUserPass(pass, secHandler)
      keyBegins = makeFileKey(pass, secHandler)
      if ( secHandler.encRevision > 2 ) then
        out = Digest::MD5.digest(PassPadBytes.pack("C*") + secHandler.fileID)
        #zero doesn't matter
        20.times{ |i| out=RC4.new(xorEachByte(keyBegins, i)).decrypt(out) }
      else #encRevision < 3
        out = RC4.new(keyBegins).encrypt(PassPadBytes.pack("C*"))
      end
      secHandler.userKey[(0...16)] == out ? keyBegins : nil
    end


    def self.stream( buf, secHandler, idgen )
      id, gen = idgen[0..1]
      objKey = secHandler.key.dup
      (0..2).each { |e| objKey << (id >> e*8 & 0xFF ) }
      (0..1).each { |e| objKey << (gen >> e*8 & 0xFF ) }
      rc4 = RC4.new( Digest::MD5.digest(objKey) )
      rc4.decrypt(buf)
    end

    def self.xorEachByte(buf, int)
      buf.each_byte.map{ |b| b^int}.pack("C*")
    end

    def self.padPass(p="")
        if p.nil? || p.empty?
          PassPadBytes.pack('C*')
        else
          p[(0...32)] + PassPadBytes[0...(32-p.length)].pack('C*')
        end
    end

    def self.printBuf(buf,name)
      print "#{name}:"
      buf.to_s.each_byte{ |b| print(":%02X"%b) }
      print "\n"
    end
  end
end
