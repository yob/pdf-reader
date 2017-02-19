# coding: utf-8

class PDF::Reader

  # A null object security handler. Used when we don't support the encryption type in a file.
  class NullSecurityHandler
    def decrypt(buf, ref)
      raise PDF::Reader::EncryptedPDFError, "Unsupported encryption style"
    end
  end
end
