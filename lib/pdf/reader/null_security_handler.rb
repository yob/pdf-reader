# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader

  # A null object security handler. Used when a PDF is unencrypted.
  class NullSecurityHandler

    def decrypt(buf, _ref)
      buf
    end
  end
end
