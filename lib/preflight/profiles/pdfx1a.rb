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

      # these don't contradict the pdfx/1a spec, but they help ensure
      # quality files for a printer. Consider moving them to a differnt
      # profile
      warn Preflight::Rules::NoProprietaryFonts
      warn Preflight::Rules::NoFontSubsets
      warn Preflight::Rules::MinPpi, 298
    end
  end
end
