# coding: utf-8

module Preflight
  module Profiles
    class PDFX1A
      include Preflight::Profile

      profile_name "pdfx-1a"

      # hard failures of the pdfx/1a spec
      error Preflight::Rules::CompressionAlgorithms, :CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode
      error Preflight::Rules::DocumentId
      error Preflight::Rules::NoEncryption
      error Preflight::Rules::OnlyEmbeddedFonts
      error Preflight::Rules::BoxNesting
      error Preflight::Rules::MaxVersion, 1.4
      error Preflight::Rules::PrintBoxes

    end
  end
end
