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
################################################################################
#
# The algorithms in this file were developed from descriptions found in
# the PDF 32000-1:2008 specification section 7.6.3.  All included page
# and section numbers are references to the appropriate section in this document.
#
################################################################################
  class Decrypt
    require 'digest/md5'
    require 'rc4'

    ## 7.6.3.3 Encryption Key Algorithm (pp61)
    #
    # needs a document's user password to build a key for decrypting an
    # encrypted PDF document
    #
    PassPadBytes = [ 0x28, 0xbf, 0x4e, 0x5e, 0x4e, 0x75, 0x8a, 0x41,
                     0x64, 0x00, 0x4e, 0x56, 0xff, 0xfa, 0x01, 0x08,
                     0x2e, 0x2e, 0x00, 0xb6, 0xd0, 0x68, 0x3e, 0x80,
                     0x2f, 0x0c, 0xa9, 0xfe, 0x64, 0x53, 0x69, 0x7a ]

    def self.makeFileKey( user_pass, sec_handler )
      # a) if there's a password, pad it to 32 bytes, else, just use the padding.
      @buf  = padPass(user_pass)
      # c) add owner key
      @buf << sec_handler.owner_key
      # d) add permissions 1 byte at a time, in little-endian order
      (0..24).step(8){|e| @buf << (sec_handler.permissions >> e & 0xFF)}
      # e) add the file ID
      @buf << sec_handler.file_id
      # f) if revision > 4 then if encryptMetadata add 4 bytes of 0x00 else add 4 bytes of 0xFF
      if (sec_handler.revision > 4)
        @buf << [ sec_handler.encryptMetadata ? 0x00 : 0xFF ].pack('C')*4
      end
      # b) init MD5 digest + g) finish the hash
      md5 = Digest::MD5.digest(@buf)
      # h) spin hash 50 times
      if (sec_handler.revision > 2) then
        50.times {
          md5 = Digest::MD5.digest(md5[(0...sec_handler.key_length)])
        }
      end
      # i) n = key_length revision > 3, n = 5 revision == 2
      md5[(0...((sec_handler.revision < 3) ? 5 : sec_handler.key_length))]
    end

    ## 7.6.3.4 Password Algorithms
    #
    # Algorithm 7 - Authenticating the Owner Password
    #
    # Used to test Owner passwords
    #
    # if the string is a valid owner password this will return the user
    # password that should be used to decrypt the document.
    #
    # if the supplied password is not a valid owner password for this document
    # then it returns nil
    #
    def self.authOwnerPass(pass, sec_handler)
      md5 = Digest::MD5.digest(padPass(pass))
      if ( sec_handler.revision > 2 ) then
        50.times { md5 = Digest::MD5.digest(md5) }
        keyBegins = md5[(0...sec_handler.key_length)]
        #first itteration decrypt owner_key
        out = sec_handler.owner_key
        #RC4 keyed with (keyBegins XOR with itteration #) to decrypt previous out
        19.downto(0).each { |i| out=RC4.new(xorEachByte(keyBegins,i)).decrypt(out) }
      else #revision < 3
        out = RC4.new( md5[(0...5)] ).decrypt( sec_handler.owner_key )
      end
      # c) check output as user password
      authUserPass( out, sec_handler )
    end

    # Algorithm 6 - Authenticating the User Password
    #
    # Used to test User passwords
    #
    # if the string is a valid user password this will return the user
    # password that should be used to decrypt the document.
    #
    # if the supplied password is not a valid user password for this document
    # then it returns nil
    #
    def self.authUserPass(pass, sec_handler)
      keyBegins = makeFileKey(pass, sec_handler)
      if ( sec_handler.revision > 2 ) then
        #initialize out for first itteration
        out = Digest::MD5.digest(PassPadBytes.pack("C*") + sec_handler.file_id)
        #zero doesn't matter -> so from 0-19
        20.times{ |i| out=RC4.new(xorEachByte(keyBegins, i)).decrypt(out) }
      else #revision < 3
        out = RC4.new(keyBegins).encrypt(PassPadBytes.pack("C*"))
      end
      sec_handler.user_key[(0...16)] == out ? keyBegins : nil
    end

    ##7.6.2 General Encryption Algorithm
    #
    # Algorithm 1: Encryption of data using the RC4 or AES algorithms
    #
    # used to decrypt RC4 encrypted PDF streams (buf)
    #
    def self.stream( buf, sec_handler, idgen )
      id, gen = idgen[0..1]
      objKey = sec_handler.encrypt_key.dup
      (0..2).each { |e| objKey << (id >> e*8 & 0xFF ) }
      (0..1).each { |e| objKey << (gen >> e*8 & 0xFF ) }
      rc4 = RC4.new( Digest::MD5.digest(objKey) )
      rc4.decrypt(buf)
    end

    # Returns input buf XORed byte by byte  with one byte int
    def self.xorEachByte(buf, int)
      buf.each_byte.map{ |b| b^int}.pack("C*")
    end

    # Pads supplied password to 32bytes using PassPadBytes as specified on
    # pp61 of spec
    def self.padPass(p="")
        if p.nil? || p.empty?
          PassPadBytes.pack('C*')
        else
          p[(0...32)] + PassPadBytes[0...(32-p.length)].pack('C*')
        end
    end

    #Builds a key using this decrypt lib
    def self.build_standard_key(pass, sec_handler)
        if !(encrypt_key = authOwnerPass(pass, sec_handler)) then
          if !(encrypt_key = authUserPass(pass, sec_handler)) then
            raise PDF::Reader::EncryptedPDFError, "Invalid password (#{pass})"
          end
        end
        encrypt_key
      end #build_key
  end
end
