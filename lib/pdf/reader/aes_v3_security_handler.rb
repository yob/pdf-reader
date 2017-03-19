# coding: utf-8
require 'digest'
require 'openssl'

class PDF::Reader

  # class creates interface to encrypt dictionary for use in Decrypt
  class AesV3SecurityHandler

    def initialize(key)
      @encrypt_key = key
      @cipher = "AES-256-CBC"
    end

    ##7.6.2 General Encryption Algorithm
    #
    # Algorithm 1: Encryption of data using the RC4 or AES algorithms
    #
    # used to decrypt RC4/AES encrypted PDF streams (buf)
    #
    # buf - a string to decrypt
    # ref - a PDF::Reader::Reference for the object to decrypt
    #
    def decrypt( buf, ref )
      cipher = OpenSSL::Cipher.new(@cipher)
      cipher.decrypt
      cipher.key = @encrypt_key.dup
      cipher.iv = buf[0..15]
      cipher.update(buf[16..-1]) + cipher.final
    end

  end
end
