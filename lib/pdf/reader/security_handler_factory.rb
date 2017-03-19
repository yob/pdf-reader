# coding: utf-8

class PDF::Reader
  # Examines the Encrypt entry of a PDF trailer (if any) and returns an object that's
  # able to decrypt the file.
  class SecurityHandlerFactory

    def self.build(encrypt, doc_id, password)
      doc_id   ||= []
      password ||= ""

      if encrypt.nil?
        NullSecurityHandler.new
      elsif standard?(encrypt)
        build_standard_handler(encrypt, doc_id, password)
      elsif standard_v5?(encrypt)
        build_v5_handler(encrypt, doc_id, password)
      else
        UnimplementedSecurityHandler.new
      end
    end

    def self.build_standard_handler(encrypt, doc_id, password)
      encmeta = !encrypt.has_key?(:EncryptMetadata) || encrypt[:EncryptMetadata].to_s == "true"
      key_builder = StandardKeyBuilder.new(
        key_length: (encrypt[:Length] || 40).to_i,
        revision: encrypt[:R],
        owner_key: encrypt[:O],
        user_key: encrypt[:U],
        permissions: encrypt[:P].to_i,
        encrypted_metadata: encmeta,
        file_id: doc_id.first,
      )
      cfm = encrypt.fetch(:CF, {}).fetch(encrypt[:StmF], {}).fetch(:CFM, nil)
      if cfm == :AESV2
        AesV2SecurityHandler.new(key_builder.key(password))
      else
        Rc4SecurityHandler.new(key_builder.key(password))
      end
    end

    def self.build_v5_handler(encrypt, doc_id, password)
      key_builder = KeyBuilderV5.new(
        owner_key: encrypt[:O],
        user_key: encrypt[:U],
        owner_encryption_key: encrypt[:OE],
        user_encryption_key: encrypt[:UE],
      )
      AesV3SecurityHandler.new(key_builder.key(password))
    end

    # This handler supports all encryption that follows upto PDF 1.5 spec (revision 4)
    def self.standard?(encrypt)
      return false if encrypt.nil?

      filter = encrypt.fetch(:Filter, :Standard)
      version = encrypt.fetch(:V, 0)
      algorithm = encrypt.fetch(:CF, {}).fetch(encrypt[:StmF], {}).fetch(:CFM, nil)
      (filter == :Standard) && (encrypt[:StmF] == encrypt[:StrF]) &&
        (version <= 3 || (version == 4 && ((algorithm == :V2) || (algorithm == :AESV2))))
    end

    # This handler supports AES-256 encryption defined in PDF 1.7 Extension Level 3
    def self.standard_v5?(encrypt)
      return false if encrypt.nil?

      filter = encrypt.fetch(:Filter, :Standard)
      version = encrypt.fetch(:V, 0)
      revision = encrypt.fetch(:R, 0)
      algorithm = encrypt.fetch(:CF, {}).fetch(encrypt[:StmF], {}).fetch(:CFM, nil)
      (filter == :Standard) && (encrypt[:StmF] == encrypt[:StrF]) &&
          ((version == 5) && (revision == 5) && (algorithm == :AESV3))
    end


  end
end
