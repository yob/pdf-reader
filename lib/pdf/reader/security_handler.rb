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

  # class creates interface to encrypt dictionary for use in Decrypt
  class StandardSecurityHandler

     attr_reader :filter, :subFilter, :version, :key_length,
                 :crypt_filter, :stream_filter, :string_filter, :embedded_file_filter,
                 :encrypt_key
     attr_reader :revision, :owner_key, :user_key, :permissions, :file_id, :password

    def initialize( enc, file_id, password )
      @filter        = enc[:Filter]
      @subFilter     = enc[:SubFilter]
      @version       = enc[:V].to_i
      @key_length    = enc[:Length].to_i/8
      @crypt_filter  = enc[:CF]
      @stream_filter = enc[:StmF]
      @string_filter = enc[:StrF]
      @revision      = enc[:R].to_i
      @owner_key     = enc[:O]
      @user_key      = enc[:U]
      @permissions   = enc[:P].to_i
      @embedded_file_filter = enc[:EFF]

      @encryptMeta = enc.has_key?(:EncryptMetadata)? enc[:EncryptMetadata].to_s == "true" : true;

      @file_id       = file_id.first
      @password      = password

      @encrypt_key = Decrypt::build_standard_key(@password, self)
    end
  end
end
