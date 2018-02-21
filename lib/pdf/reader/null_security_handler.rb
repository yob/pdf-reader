# coding: utf-8

class PDF::Reader

  # A null object security handler. Used when a PDF is unencrypted.
  class NullSecurityHandler

    def decrypt(buf, _ref)
      buf
    end
  end
end
