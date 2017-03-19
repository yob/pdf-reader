# coding: utf-8

require 'digest/md5'
require 'rc4'

class PDF::Reader

  # Processes the Encrypt dict from an encrypted PDF and a user provided
  # password and returns a key that can decrypt the file.
  #
  # This can generate a key compatible with the following standard encryption algorithms:
  #
  # * Version 1-3, all variants
  # * Version 4, V2 (RC4) and AESV2
  #
  class StandardKeyBuilder

    ## 7.6.3.3 Encryption Key Algorithm (pp61)
    #
    # needs a document's user password to build a key for decrypting an
    # encrypted PDF document
    #
    PassPadBytes = [ 0x28, 0xbf, 0x4e, 0x5e, 0x4e, 0x75, 0x8a, 0x41,
                     0x64, 0x00, 0x4e, 0x56, 0xff, 0xfa, 0x01, 0x08,
                     0x2e, 0x2e, 0x00, 0xb6, 0xd0, 0x68, 0x3e, 0x80,
                     0x2f, 0x0c, 0xa9, 0xfe, 0x64, 0x53, 0x69, 0x7a ]

    def initialize(opts = {})
      @key_length    = opts[:key_length].to_i/8
      @revision      = opts[:revision].to_i
      @owner_key     = opts[:owner_key]
      @user_key      = opts[:user_key]
      @permissions   = opts[:permissions].to_i
      @encryptMeta   = opts.fetch(:encrypted_metadata, true)
      @file_id       = opts[:file_id] || ""

      if @key_length != 5 && @key_length != 16
        msg = "StandardKeyBuilder only supports 40 and 128 bit\
               encryption (#{@key_length * 8}bit)"
        raise ArgumentError, msg
      end
    end

    # Takes a string containing a user provided password.
    #
    # If the password matches the file, then a string containing a key suitable for
    # decrypting the file will be returned. If the password doesn't match the file,
    # and exception will be raised.
    #
    def key(pass)
      pass ||= ""
      encrypt_key   = auth_owner_pass(pass)
      encrypt_key ||= auth_user_pass(pass)

      raise PDF::Reader::EncryptedPDFError, "Invalid password (#{pass})" if encrypt_key.nil?
      encrypt_key
    end

    private

    # Pads supplied password to 32bytes using PassPadBytes as specified on
    # pp61 of spec
    def pad_pass(p="")
      if p.nil? || p.empty?
        PassPadBytes.pack('C*')
      else
        p[0, 32] + PassPadBytes[0, 32-p.length].pack('C*')
      end
    end

    def xor_each_byte(buf, int)
      buf.each_byte.map{ |b| b^int}.pack("C*")
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
    def auth_owner_pass(pass)
      md5 = Digest::MD5.digest(pad_pass(pass))
      if @revision > 2 then
        50.times { md5 = Digest::MD5.digest(md5) }
        keyBegins = md5[0, @key_length]
        #first iteration decrypt owner_key
        out = @owner_key
        #RC4 keyed with (keyBegins XOR with iteration #) to decrypt previous out
        19.downto(0).each { |i| out=RC4.new(xor_each_byte(keyBegins,i)).decrypt(out) }
      else
        out = RC4.new( md5[0, 5] ).decrypt( @owner_key )
      end
      # c) check output as user password
      auth_user_pass( out )
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
    def auth_user_pass(pass)
      keyBegins = make_file_key(pass)
      if @revision >= 3
        #initialize out for first iteration
        out = Digest::MD5.digest(PassPadBytes.pack("C*") + @file_id)
        #zero doesn't matter -> so from 0-19
        20.times{ |i| out=RC4.new(xor_each_byte(keyBegins, i)).encrypt(out) }
        pass = @user_key[0, 16] == out
      else
        pass = RC4.new(keyBegins).encrypt(PassPadBytes.pack("C*")) == @user_key
      end
      pass ? keyBegins : nil
    end

    def make_file_key( user_pass )
      # a) if there's a password, pad it to 32 bytes, else, just use the padding.
      @buf  = pad_pass(user_pass)
      # c) add owner key
      @buf << @owner_key
      # d) add permissions 1 byte at a time, in little-endian order
      (0..24).step(8){|e| @buf << (@permissions >> e & 0xFF)}
      # e) add the file ID
      @buf << @file_id
      # f) if revision >= 4 and metadata not encrypted then add 4 bytes of 0xFF
      if @revision >= 4 && !@encryptMeta
        @buf << [0xFF,0xFF,0xFF,0xFF].pack('C*')
      end
      # b) init MD5 digest + g) finish the hash
      md5 = Digest::MD5.digest(@buf)
      # h) spin hash 50 times
      if @revision >= 3
        50.times {
          md5 = Digest::MD5.digest(md5[0, @key_length])
        }
      end
      # i) n = key_length revision >= 3, n = 5 revision == 2
      if @revision < 3
        md5[0, 5]
      else
        md5[0, @key_length]
      end
    end

  end
end
