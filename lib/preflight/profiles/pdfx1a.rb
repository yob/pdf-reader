# coding: utf-8

module Preflight
  module Profiles
    class PDFX1A
      include Preflight::Profile

      profile_name "pdfx-1a"

      # hard failures of the pdfx/1a spec
      rule Preflight::Rules::CompressionAlgorithms, :CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode
      rule Preflight::Rules::DocumentId
      rule Preflight::Rules::NoEncryption
      rule Preflight::Rules::OnlyEmbeddedFonts
      rule Preflight::Rules::BoxNesting
      rule Preflight::Rules::MaxVersion, 1.4
      rule Preflight::Rules::PrintBoxes

    end
  end
end
