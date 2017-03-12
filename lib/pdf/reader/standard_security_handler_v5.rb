# coding: utf-8
require 'digest'
require 'openssl'

class PDF::Reader

  # class creates interface to encrypt dictionary for use in Decrypt
  class StandardSecurityHandlerV5

    attr_reader :key_length, :encrypt_key

    def initialize(opts = {})
      @key_length  = 256
      @encrypt_key = build_standard_key(opts)

      raise ArgumentError, 'Incorrect Password' unless @encrypt_key
    end

    # This handler supports AES-256 encryption defined in PDF 1.7 Extension Level 3
    def self.supports?(encrypt)
      return false if encrypt.nil?

      filter = encrypt.fetch(:Filter, :Standard)
      version = encrypt.fetch(:V, 0)
      revision = encrypt.fetch(:R, 0)
      algorithm = encrypt.fetch(:CF, {}).fetch(encrypt[:StmF], {}).fetch(:CFM, nil)
      (filter == :Standard) && (encrypt[:StmF] == encrypt[:StrF]) &&
          ((version == 5) && (revision == 5) && (algorithm == :AESV3))
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
      cipher = OpenSSL::Cipher.new("AES-#{@key_length}-CBC")
      cipher.decrypt
      cipher.key = @encrypt_key.dup
      cipher.iv = buf[0..15]
      cipher.update(buf[16..-1]) + cipher.final
    end

    private
    # Algorithm 3.2a - Computing an encryption key
    #
    # Defined in PDF 1.7 Extension Level 3
    #
    # if the string is a valid user/owner password, this will return the decryption key
    #
    def build_standard_key(opts)
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      sha256 = Digest::SHA256.new

      o = opts[:O]    # hash(32B) + validation salt(8B) + key salt(8B)
      u = opts[:U]    # hash(32B) + validation salt(8B) + key salt(8B)
      oe = opts[:OE]  # decryption key, encrypted w/ owner password
      ue = opts[:UE]  # decryption key, encrypted w/ user password
      pass = (opts[:password] || '')[0...127]   # UTF-8 encoded password. first 127 bytes

      # test for owner pass
      sha256.update(pass)
      sha256.update(o[32..39])      # O validation salt
      sha256.update(u)
      if sha256.digest == o[0..31]  # O hash
        sha256.reset
        sha256.update(pass)
        sha256.update(o[40..-1])    # O key salt
        sha256.update(u)

        cipher.decrypt
        cipher.key = sha256.digest
        cipher.iv = "\x00" * 16
        cipher.padding = 0
        return cipher.update(oe) + cipher.final
      end

      sha256.reset
      cipher.reset

      # test for user pass
      sha256.update(pass)
      sha256.update(u[32..39])      # U validation salt
      if sha256.digest == u[0..31]  # U hash
        sha256.reset
        sha256.update(pass)
        sha256.update(u[40..-1])    # U key salt

        cipher.decrypt
        cipher.key = sha256.digest
        cipher.iv = "\x00" * 16
        cipher.padding = 0
        return cipher.update(ue) + cipher.final
      end
    end
  end
end
