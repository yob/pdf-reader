# coding: utf-8

module Preflight
  module Profiles
    class PDFX1A
      include Preflight::Profile

      profile_name "pdfx-1a"

      rule Preflight::Rules::MatchInfoEntries, {:GTS_PDFXVersion => /\APDF\/X/,
                                                :GTS_PDFXConformance => /\APDF\/X-1a/}
      rule Preflight::Rules::RootHasKeys, :OutputIntents
      rule Preflight::Rules::InfoHasKeys, :Title, :CreationDate, :ModDate
      rule Preflight::Rules::InfoSpecifiesTrapping
      rule Preflight::Rules::CompressionAlgorithms, :CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode
      rule Preflight::Rules::DocumentId
      rule Preflight::Rules::NoEncryption
      rule Preflight::Rules::NoFilespecs
      rule Preflight::Rules::OnlyEmbeddedFonts
      rule Preflight::Rules::BoxNesting
      rule Preflight::Rules::MaxVersion, 1.4
      rule Preflight::Rules::PrintBoxes
      rule Preflight::Rules::OutputIntentForPdfx
      rule Preflight::Rules::PdfxOutputIntentHasKeys, :OutputConditionIdentifier, :Info

    end
  end
end
