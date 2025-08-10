# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader

  # A null object security handler. Used when a PDF is unencrypted.
  class NullSecurityHandler

    #: (String, PDF::Reader::Reference) -> String
    def decrypt(buf, _ref)
      buf
    end
  end
end
