# coding: utf-8
# frozen_string_literal: true

module Marron

  # Security handler for when we don't support the flavour of encryption
  # used in a PDF.
  class UnimplementedSecurityHandler
    def self.supports?(encrypt)
      true
    end

    def decrypt(buf, ref)
      raise Marron::EncryptedPDFError, "Unsupported encryption style"
    end
  end
end
