# coding: utf-8

module Preflight
  module Profiles
    class PDFA1A
      include Preflight::Profile

      profile_name "pdfa-1a"

      # hard failures of the pdfx/1a spec
      error Preflight::Rules::CompressionAlgorithms, :CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode
      error Preflight::Rules::NoEncryption
      error Preflight::Rules::OnlyEmbeddedFonts

    end
  end
end
