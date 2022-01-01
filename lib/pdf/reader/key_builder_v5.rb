# coding: utf-8
# typed: strict
# frozen_string_literal: true

require 'digest/md5'
require 'rc4'

class PDF::Reader

  # Processes the Encrypt dict from an encrypted PDF and a user provided
  # password and returns a key that can decrypt the file.
  #
  # This can generate a decryption key compatible with the following standard encryption algorithms:
  #
  # * Version 5 (AESV3)
  #
  class KeyBuilderV5

    def initialize(opts = {})
      @key_length   = 256

      # hash(32B) + validation salt(8B) + key salt(8B)
      @owner_key    = opts[:owner_key] || ""

      # hash(32B) + validation salt(8B) + key salt(8B)
      @user_key     = opts[:user_key] || ""

      # decryption key, encrypted w/ owner password
      @owner_encryption_key = opts[:owner_encryption_key] || ""

      # decryption key, encrypted w/ user password
      @user_encryption_key  = opts[:user_encryption_key] || ""
    end

    # Takes a string containing a user provided password.
    #
    # If the password matches the file, then a string containing a key suitable for
    # decrypting the file will be returned. If the password doesn't match the file,
    # and exception will be raised.
    #
    def key(pass)
      pass = pass.byteslice(0...127).to_s   # UTF-8 encoded password. first 127 bytes

      encrypt_key   = auth_owner_pass(pass)
      encrypt_key ||= auth_user_pass(pass)
      encrypt_key ||= auth_owner_pass_r6(pass)
      encrypt_key ||= auth_user_pass_r6(pass)

      raise PDF::Reader::EncryptedPDFError, "Invalid password (#{pass})" if encrypt_key.nil?
      encrypt_key
    end

    private

    # Algorithm 3.2a - Computing an encryption key
    #
    # Defined in PDF 1.7 Extension Level 3
    #
    # if the string is a valid user/owner password, this will return the decryption key
    #
    def auth_owner_pass(password)
      if Digest::SHA256.digest(password + @owner_key[32..39] + @user_key) == @owner_key[0..31]
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.decrypt
        cipher.key = Digest::SHA256.digest(password + @owner_key[40..-1] + @user_key)
        cipher.iv = "\x00" * 16
        cipher.padding = 0
        cipher.update(@owner_encryption_key) + cipher.final
      end
    end

    def auth_user_pass(password)
      if Digest::SHA256.digest(password + @user_key[32..39]) == @user_key[0..31]
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.decrypt
        cipher.key = Digest::SHA256.digest(password + @user_key[40..-1])
        cipher.iv = "\x00" * 16
        cipher.padding = 0
        cipher.update(@user_encryption_key) + cipher.final
      end
    end

    def auth_owner_pass_r6(password)
      if r6_digest(password, @owner_key[32..39].to_s, @user_key[0,48].to_s) == @owner_key[0..31]
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.decrypt
        cipher.key = r6_digest(password, @owner_key[40,8].to_s, @user_key[0, 48].to_s)
        cipher.iv = "\x00" * 16
        cipher.padding = 0
        cipher.update(@owner_encryption_key) + cipher.final
      end
    end

    def auth_user_pass_r6(password)
      if r6_digest(password, @user_key[32..39].to_s) == @user_key[0..31]
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.decrypt
        cipher.key = r6_digest(password, @user_key[40,8].to_s)
        cipher.iv = "\x00" * 16
        cipher.padding = 0
        cipher.update(@user_encryption_key) + cipher.final
      end
    end

    # PDF 2.0 spec, 7.6.4.3.4
    # Algorithm 2.B: Computing a hash (revision 6 and later)
    def r6_digest(password, salt, user_key = '')
      k = Digest::SHA256.digest(password + salt + user_key)
      e = ''

      i = 0
      while i < 64 or e.getbyte(-1).to_i > i - 32
        k1 = (password + k + user_key) * 64

        aes = OpenSSL::Cipher.new("aes-128-cbc").encrypt
        aes.key = k[0, 16].to_s
        aes.iv = k[16, 16].to_s
        aes.padding = 0
        e = String.new(aes.update(k1))
        k = case unpack_128bit_bigendian_int(e) % 3
            when 0 then Digest::SHA256.digest(e)
            when 1 then Digest::SHA384.digest(e)
            when 2 then Digest::SHA512.digest(e)
            end
        i = i + 1
      end

      k[0, 32].to_s
    end

    def unpack_128bit_bigendian_int(str)
      ints = str[0,16].to_s.unpack("N*")
      (ints[0].to_i << 96) + (ints[1].to_i << 64) + (ints[2].to_i << 32) + ints[3].to_i
    end

  end
end

