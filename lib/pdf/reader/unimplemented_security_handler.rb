# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader

  # Security handler for when we don't support the flavour of encryption
  # used in a PDF.
  class UnimplementedSecurityHandler
    #: (untyped) -> bool
    def self.supports?(encrypt)
      true
    end

    #: (untyped, untyped) -> untyped
    def decrypt(buf, ref)
      raise PDF::Reader::EncryptedPDFError, "Unsupported encryption style"
    end
  end
end
