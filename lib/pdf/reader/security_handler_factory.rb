# coding: utf-8

class PDF::Reader
  # Examines the Encrypt entry of a PDF trailer (if any) and returns an object that's
  # able to decrypt the file.
  class SecurityHandlerFactory

    def self.build(encrypt, doc_id, password)
      doc_id   ||= []
      password ||= ""

      if NullSecurityHandler.supports?(encrypt)
        NullSecurityHandler.new
      elsif StandardSecurityHandler.supports?(encrypt)
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
        StandardSecurityHandler.new(
          key_builder.key(password),
          encrypt.fetch(:CF, {}).fetch(encrypt[:StmF], {}).fetch(:CFM, nil)
        )
      elsif StandardSecurityHandlerV5.supports?(encrypt)
        StandardSecurityHandlerV5.new(
            O: encrypt[:O],
            U: encrypt[:U],
            OE: encrypt[:OE],
            UE: encrypt[:UE],
            password: password
        )
      else
        UnimplementedSecurityHandler.new
      end
    end
  end
end
