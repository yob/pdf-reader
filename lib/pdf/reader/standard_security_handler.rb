# coding: utf-8
# typed: true
# frozen_string_literal: true

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
require 'digest/md5'
require 'openssl'
require 'rc4'

class PDF::Reader

  # class creates interface to encrypt dictionary for use in Decrypt
  class StandardSecurityHandler

    def initialize(key, cfm)
      @encrypt_key = key
      @cfm         = cfm
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
      case @cfm
        when :AESV2
          decrypt_aes128(buf, ref)
        else
          decrypt_rc4(buf, ref)
      end
    end

    private

    # decrypt with RC4 algorithm
    # version <=3 or (version == 4 and CFM == V2)
    def decrypt_rc4( buf, ref )
      objKey = @encrypt_key.dup
      (0..2).each { |e| objKey << (ref.id >> e*8 & 0xFF ) }
      (0..1).each { |e| objKey << (ref.gen >> e*8 & 0xFF ) }
      length = objKey.length < 16 ? objKey.length : 16
      rc4 = RC4.new( Digest::MD5.digest(objKey)[0,length] )
      rc4.decrypt(buf)
    end

    # decrypt with AES-128-CBC algorithm
    # when (version == 4 and CFM == AESV2)
    def decrypt_aes128( buf, ref )
      objKey = @encrypt_key.dup
      (0..2).each { |e| objKey << (ref.id >> e*8 & 0xFF ) }
      (0..1).each { |e| objKey << (ref.gen >> e*8 & 0xFF ) }
      objKey << 'sAlT'  # Algorithm 1, b)
      length = objKey.length < 16 ? objKey.length : 16
      cipher = OpenSSL::Cipher.new("AES-#{length << 3}-CBC")
      cipher.decrypt
      cipher.key = Digest::MD5.digest(objKey)[0,length]
      cipher.iv = buf[0..15]
      cipher.update(buf[16..-1]) + cipher.final
    end

  end
end
