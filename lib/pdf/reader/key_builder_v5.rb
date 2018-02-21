# coding: utf-8

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
      pass = pass.byteslice(0...127)   # UTF-8 encoded password. first 127 bytes

      encrypt_key   = auth_owner_pass(pass)
      encrypt_key ||= auth_user_pass(pass)

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
  end
end

