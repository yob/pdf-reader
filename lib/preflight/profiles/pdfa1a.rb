# coding: utf-8

module Preflight
  module Profiles
    class PDFA1A
      include Preflight::Profile

      profile_name "pdfa-1a"

      # hard failures of the pdfx/1a spec
      rule Preflight::Rules::CompressionAlgorithms, :CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode
      rule Preflight::Rules::NoEncryption
      rule Preflight::Rules::OnlyEmbeddedFonts

    end
  end
end
