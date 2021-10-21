# coding: utf-8

# These specs are a kind of integration spec. They're not unit testing small pieces
# of code, it's just parsing a range of PDF files and ensuring the result is
# consistent. An extra check to make sure parsing these files will continue
# to work for our users.
#
# Where possible, specs that unit test correctly should be written in addition to
# these

describe PDF::Reader, "integration specs" do

  context "cairo-unicode-short" do
    let(:filename) { pdf_spec_file("cairo-unicode-short") }

    it "interprets unicode strings correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eql("Chunky Bacon")
      end
    end
  end

  context "vertical-text-in-identity-v" do
    let(:filename) { pdf_spec_file("vertical-text-in-identity-v") }

    it "interprets Identity-V encoded strings correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text.split.map(&:strip)).to eql(%w{V e r t i c a l T e x t})
      end
    end
  end

  context "adobe_sample" do
    let(:filename) { pdf_spec_file("adobe_sample") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("This is a sample PDF file")
        expect(page.text).to include("If you can read this, you already have Adobe Acrobat")
      end
    end
  end

  context "dutch PDF with NBSP characters" do
    let(:filename) { pdf_spec_file("dutch") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.pages.size).to eql(3)

        page = reader.page(1)
        expect(page.text).to include("Dit\302\240is\302\240een\302\240pdf\302\240test\302\240van\302\240drie\302\240pagina")
        expect(page.text).to include("’s")
        expect(page.text).to include("Pagina\302\2401")
      end
    end
  end

  context "PDF with a difference table" do
    let(:filename) { pdf_spec_file("difference_table") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eql("Goiás")
      end
    end
  end

  context "PDF with a difference table (v2)" do
    let(:filename) { pdf_spec_file("difference_table2") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eql("This PDF contains ligatures,for example in “ﬁle”and “ﬂoor”.")
      end
    end
  end

  context "PDF with a content stream that has trailing whitespace" do
    let(:filename) { pdf_spec_file("content_stream_trailing_whitespace") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to match(/Tax\s+Invoice/)
      end
    end
  end

  context "PDF with a content stream that is enclosed with CR characters only" do
    let(:filename) { pdf_spec_file("content_stream_cr_only") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("This is a weird PDF file")
      end
    end
  end

  context "PDF with a content stream that is missing an operator (has hanging params)" do
    let(:filename) { pdf_spec_file("content_stream_missing_final_operator") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to match(/Locatrix/)
        expect(reader.page(2).text).to match(/Ubuntu/)
      end
    end
  end

  # this spec is to detect an hard lock issue some people were encountering on some OSX
  # systems. Real pain to debug.
  context "PDF with a string containing a high byte (D1) under MacRomanEncoding" do
    let(:filename) { pdf_spec_file("hard_lock_under_osx") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text[0,1]).to eql("’")
      end
    end
  end

  context "PDF that has a content stream with a broken string" do
    let(:filename) { pdf_spec_file("broken_string") }

    # this file used to get us into a hard, endless loop. Make sure that doesn't still happen
    it "doesn't hang when extracting doc info" do
      Timeout::timeout(3) do
        expect {
          reader = PDF::Reader.new(filename)
          reader.info
        }.to raise_error(PDF::Reader::MalformedPDFError)
      end
    end
  end

  context "PDF with a stream that has its length specified as an indirect reference" do
    let(:filename) { pdf_spec_file("content_stream_with_length_as_ref") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to eql("Hello World")
      end
    end
  end

  # PDF::Reader::XRef#object was saving an incorrect position when seeking. We
  # were saving the current pos of the underlying IO stream, then seeking back
  # to it. This was fine, except when there was still content in the buffer.
  context "PDF with a stream that has its length specified as an indirect reference and uses windows line breaks" do
    let(:filename) { pdf_spec_file("content_stream_with_length_as_ref_and_windows_breaks") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to eql("Hello World")
      end
    end
  end

  context "PDF has a content stream refers to a non-existant font" do
    let(:filename) { pdf_spec_file("content_stream_refers_to_invalid_font") }

    it "raises an exception" do
      expect {
        reader = PDF::Reader.new(filename)
        reader.page(1).text
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  context "Empty file" do
    it "raises an exception" do
      expect {
        PDF::Reader.new(StringIO.new(""))
      }.to raise_error(PDF::Reader::MalformedPDFError)
    end
  end

  context "PDF that uses an ASCII85Decode filter" do
    let(:filename) { pdf_spec_file("ascii85_filter") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to match(/Et Iunia se/)
      end
    end
  end

  context "PDF that has an inline image in a content stream with no line breaks" do
    let(:filename) { pdf_spec_file("inline_image_single_line_content_stream") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text.strip[0,7]).to eql("WORKING")
      end
    end
  end

  context "PDF that uses Form XObjects to repeat content" do
    let(:filename) { pdf_spec_file("form_xobject") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to eql("James Healy")
        expect(reader.page(2).text).to eql("James Healy")
      end
    end
  end

  context "PDF that uses Form XObjects to repeat content" do
    let(:filename) { pdf_spec_file("form_xobject_more") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to include("Some regular content")
        expect(reader.page(1).text).to include("James Healy")
        expect(reader.page(2).text).to include("€10")
        expect(reader.page(2).text).to include("James Healy")
      end
    end
  end

  context "PDF that uses indirect Form XObjects to repeat content" do
    let(:filename) { pdf_spec_file("indirect_xobject") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).not_to be_nil
      end
    end
  end

  context "PDF that has a Form XObjects that references itself" do
    let(:filename) { pdf_spec_file("form_xobject_recursive") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to include("this form XObject contains a reference to itself")
      end
    end
  end

  context "PDF that uses multiple content streams for a single page" do
    let(:filename) { pdf_spec_file("split_params_and_operator") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to include("My name is")
        expect(reader.page(1).text).to include("James Healy")
      end
    end
  end

  context "PDF that has a single space after the EOF marker" do
    let(:filename) { pdf_spec_file("space_after_eof") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to eql("Hello World")
      end
    end
  end

  context "PDF that was generated in open office 3" do
    let(:filename) { pdf_spec_file("oo3") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to include("test")
      end
    end
  end

  context "PDF has newlines at the start of a content stream" do
    let(:filename) { pdf_spec_file("content_stream_begins_with_newline") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to eql("This file has a content stream that begins with \\n\\n")
      end
    end
  end

  context "encrypted_version1_revision2_40bit_rc4_user_pass_apples" do
    let(:filename) { pdf_spec_file("encrypted_version1_revision2_40bit_rc4_user_pass_apples") }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate=>"D:20170115142929+11'00'"
          )
        end
      end
    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate=>"D:20170115142929+11'00'"
          )
        end
      end
    end
  end

  context "encrypted_version1_revision2_128bit_rc4_blank_user_password" do
    let(:filename) { pdf_spec_file("encrypted_version1_revision2_128bit_rc4_blank_user_password") }

    context "with no user pass" do
      it "correctly extracts text" do
        PDF::Reader.open(filename) do |reader|
          expect(reader.page(1).text).to eql("WOOOOO DOCUMENT!")
        end
      end
    end

    context "with the owner pass" do
      it "correctly extracts text"
    end
  end

  context "encrypted_version2_revision3_128bit_rc4_blank_user_pass" do
    let(:filename) { pdf_spec_file("encrypted_version2_revision3_128bit_rc4_blank_user_pass") }

    context "with no user pass" do
      it "correctly extracts text" do
        PDF::Reader.open(filename) do |reader|
          expect(reader.page(1).text).to eql("This sample file is encrypted with no user password")
        end
      end
    end

    context "with the owner pass" do
      it "correctly extracts text"
    end

  end

  context "encrypted_version1_revision2_128bit_rc4_no_doc_id" do
    let(:filename) {pdf_spec_file("encrypted_version1_revision2_128bit_rc4_no_doc_id") }

    context "with no user pass" do
      it "correctly extracts text" do
        PDF::Reader.open(filename) do |reader|
          expect(reader.page(1).text).to eql(
            "This encryped file breaks compatability with the PDF spec " \
            "because it has no document ID"
          )
        end
      end
    end

    context "with the owner pass" do
      it "correctly extracts text"
    end
  end

  context "encrypted_version2_revision3_128bit_rc4_user_pass_apples" do
    let(:filename) { pdf_spec_file("encrypted_version2_revision3_128bit_rc4_user_pass_apples") }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'"
          )
        end
      end
    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'"
          )
        end
      end
    end

    context "with no pass" do
      it "raises an exception" do
        expect {
          PDF::Reader.open(filename) do |reader|
            reader.page(1).text
          end
        }.to raise_error(PDF::Reader::EncryptedPDFError)
      end
    end
  end

  context "encrypted_version4_revision_4user_pass_apples_enc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version4_revision4_128bit_rc4_user_pass_apples_enc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate=>"D:20170114125054+11'00'"
          )
        end
      end
    end
    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate=>"D:20170114125054+11'00'"
          )
        end
      end
    end
  end

  context "encrypted_version4_revision4_128bit_rc4_user_pass_apples_unenc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version4_revision4_128bit_rc4_user_pass_apples_unenc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }
      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate => "D:20170114125141+11'00'"
          )
        end
      end
    end
    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :Creator=>"Writer",
            :Producer=>"LibreOffice 3.3",
            :CreationDate=>"D:20110814231057+10'00'",
            :ModDate => "D:20170114125141+11'00'"
          )
        end
      end
    end
  end

  context "encrypted_version4_revision4_128bit_aes_user_pass_apples_enc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version4_revision4_128bit_aes_user_pass_apples_enc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :CreationDate=>"D:20110814231057+10'00'",
            :Creator=>"Writer",
            :ModDate=>"D:20170115224117+11'00'",
            :Producer=>"LibreOffice 3.3",
          )
        end
      end
    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :CreationDate=>"D:20110814231057+10'00'",
            :Creator=>"Writer",
            :ModDate=>"D:20170115224117+11'00'",
            :Producer=>"LibreOffice 3.3",
          )
        end
      end

    end
  end

  context "encrypted_version4_revision4_128bit_aes_user_pass_apples_unenc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version4_revision4_128bit_aes_user_pass_apples_unenc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :CreationDate=>"D:20110814231057+10'00'",
            :Creator=>"Writer",
            :ModDate=>"D:20170115224244+11'00'",
            :Producer=>"LibreOffice 3.3",
          )
        end
      end

    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
            :CreationDate=>"D:20110814231057+10'00'",
            :Creator=>"Writer",
            :ModDate=>"D:20170115224244+11'00'",
            :Producer=>"LibreOffice 3.3",
          )
        end
      end

    end
  end

  context "encrypted_version5_revision5_256bit_aes_user_pass_apples_enc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version5_revision5_256bit_aes_user_pass_apples_enc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
                                     :Author => "Gyuchang Jun",
                                     :CreationDate => "D:20170312093033+00'00'",
                                     :Creator => "Microsoft Word",
                                     :ModDate => "D:20170312093033+00'00'"
                                 )
        end
      end
    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
                                     :Author => "Gyuchang Jun",
                                     :CreationDate => "D:20170312093033+00'00'",
                                     :Creator => "Microsoft Word",
                                     :ModDate => "D:20170312093033+00'00'"
                                 )
        end
      end

    end
  end

  context "encrypted_version5_revision5_256bit_aes_user_pass_apples_unenc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version5_revision5_256bit_aes_user_pass_apples_unenc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
                                     :Author => "Gyuchang Jun",
                                     :CreationDate => "D:20170312093033+00'00'",
                                     :Creator => "Microsoft Word",
                                     :ModDate => "D:20170312093033+00'00'"
                                 )
        end
      end

    end

    context "with the owner pass" do
      let(:pass) { "password" }

      it "correctly extracts text" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.page(1).text).to include("This sample file is encrypted")
        end
      end

      it "correctly extracts info" do
        PDF::Reader.open(filename, :password => pass) do |reader|
          expect(reader.info).to eq(
                                     :Author => "Gyuchang Jun",
                                     :CreationDate => "D:20170312093033+00'00'",
                                     :Creator => "Microsoft Word",
                                     :ModDate => "D:20170312093033+00'00'"
                                 )
        end
      end

    end
  end

  context "encrypted_version5_revision6_256bit_aes_user_pass_apples_enc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version5_revision6_256bit_aes_user_pass_apples_enc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      # TODO: remove this spec
      it "raises UnsupportedFeatureError" do
        expect {
          PDF::Reader.open(filename, :password => pass) do |reader|
            reader.page(1).text
          end
        }.to raise_error(PDF::Reader::EncryptedPDFError)
      end

      it "correctly extracts text"
      it "correctly extracts info"
    end

    context "with the owner pass" do
      it "correctly extracts text"
      it "correctly extracts info"
    end
  end

  context "encrypted_version5_revision6_256bit_aes_user_pass_apples_unenc_metadata" do
    let(:filename) {
      pdf_spec_file("encrypted_version5_revision6_256bit_aes_user_pass_apples_unenc_metadata")
    }

    context "with the user pass" do
      let(:pass) { "apples" }

      # TODO: remove this spec
      it "raises UnsupportedFeatureError" do
        expect {
          PDF::Reader.open(filename, :password => pass) do |reader|
            reader.page(1).text
          end
        }.to raise_error(PDF::Reader::EncryptedPDFError)
      end

      it "correctly extracts text"
      it "correctly extracts info"
    end

    context "with the owner pass" do
      it "correctly extracts text"
      it "correctly extracts info"
    end
  end

  context "Encrypted PDF with an xref stream" do
    let(:filename) {
      pdf_spec_file("encrypted_and_xref_stream")
    }

    it "correctly extracts text" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to eq("This text is encrypted")
      end
    end

    it "correctly parses indirect objects" do
      PDF::Reader.open(filename) do |reader|
        expect { reader.objects.values }.not_to raise_error
      end
    end
  end

  context "PDF with inline images" do
    let(:filename) { pdf_spec_file("inline_image") }

    it "extracts inline images correctly" do
      @browser = PDF::Reader.new(filename)
      @page    = @browser.page(1)

      receiver = PDF::Reader::RegisterReceiver.new
      @page.walk(receiver)

      callbacks = receiver.series(:begin_inline_image, :begin_inline_image_data, :end_inline_image)

      # inline images should trigger 3 callbacks. The first with no args.
      expect(callbacks[0]).to eql(:name => :begin_inline_image, :args => [])

      # the second with the image header (colorspace, etc)
      expect(callbacks[1]).to eql(:name => :begin_inline_image_data, :args => [:CS, :RGB, :I, true, :W, 234, :H, 70, :BPC, 8])

      # the last with the image data
      expect(callbacks[2][:name]).to eql :end_inline_image
      image_data =  callbacks[2][:args].first

      expect(image_data).to be_a(String)
      expect(image_data.size).to  eql 49140
      expect(image_data[0,3].unpack("C*")).to   eql [255,255,255]
      expect(image_data[-3,3].unpack("C*")).to  eql [255,255,255]
    end
  end

  context "PDF with a page that has multiple content streams" do
    let(:filename) { pdf_spec_file("content_stream_as_array") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        expect(reader.page(1).text).to include("Arkansas Declaration Relating")
      end
    end
  end

  context "PDF with a junk prefix" do
    let(:filename) { pdf_spec_file("junk_prefix") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eql("This PDF contains junk before the %-PDF marker")
      end
    end
  end

  context "PDF with a 1024 bytes of junk prefix" do
    let(:filename) { pdf_spec_file("junk_prefix_1024") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eql("This PDF contains junk before the %-PDF marker")
      end
    end
  end

  context "PDF that has a cmap entry that uses ligatures" do
    let(:filename) { pdf_spec_file("ligature_integration_sample") }

    it "extracts text correctly" do
      # there are two locations in the following pdf that have the following sequence
      # [ 85,   68,   73,    192,        70]   after cmap translation this should yield
      # [[114], [97], [102], [102, 105], [99]] or more specifically
      # [r,     a,    f,     fi,         c]
      #
      # prior to commit d37b4bf52e243dfb999fa0cda791449c50f6d16d
      # the fi would be returned as f

      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        m = /raffic/.match(page.text)
        expect(m[0].to_s).to eql("raffic")
      end
    end
  end

  context "PDF that has a cmap entry that contains surrogate pairs" do
    let(:filename) { pdf_spec_file("surrogate_pair_integration_sample") }

    it "extracts text correctly" do
      # the following pdf has a sequence in it that requires 32-bit Unicode, pdf requires
      # all text to be stored in 16-bit. To acheive this surrogate-pairs are used. cmap
      # converts the surrogate-pairs back to 32-bit and ruby handles them nicely.
      # the following sequence exists in this pdf page
      # \u{1d475}\u{1d468}\u{1d47a}\u{1d46a}\u{1d468}\u{1d479} => NASCAR
      # these codepoints are in the "Math Alphanumeric Symbols (Italic) section of Unicode"
      #
      # prior to commit d37b4bf52e243dfb999fa0cda791449c50f6d16d
      # pdf-reader would return Nil instead of the correct unicode character
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        # 𝑵𝑨𝑺𝑪𝑨𝑹
        utf8_str = [0x1d475, 0x1d468, 0x1d47a, 0x1d46a, 0x1d468, 0x1d479].pack("U*")
        expect(page.text).to include(utf8_str)
      end
    end
  end

  context "PDF that uses a standatd font and a ligature" do
    let(:filename) { pdf_spec_file("standard_font_with_a_difference") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("The following word uses a ligature: ﬁve")
      end
    end
  end

  context "PDF that uses a type1 font that isn't embedded and isn't one of the 14 built-ins" do
    let(:filename) { pdf_spec_file("type1-arial") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("This text uses a Type1 font that isn't embedded")
      end
    end
  end

  context "PDF that uses a TrueType font that isn't embedded and has no metrics" do
    let(:filename) { pdf_spec_file("truetype-arial") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to start_with("This text uses a TrueType font that isn't embedded")
      end
    end
  end

  context "PDF that uses a type3 bitmap font" do
    let(:filename) { pdf_spec_file("type3_font") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("a\nb\nc")
      end
    end
  end

  context "PDF that uses a type3 bitmap font with a rare FontMatrix" do
    let(:filename) { pdf_spec_file("type3_font_with_rare_font_matrix") }

    # TODO most type3 fonts have a FontMatrix entry of [ 0.001 0 0 0.001 0 0 ],
    # which matches the glyph scale factor of 1000 that non-type3 fonts use.
    # It's permitted for type3 fonts to use other FontMatrix values though,
    # and we should do a better job of extracting the text.
    # The Page is 200pts wide and 50pts high. The first letters for each word
    # *should* be positioned like so:
    #
    #   P - X: 10.3 Y: 20   Width: 7.35 Height: 8.55
    #   G - X: 56.5 Y: 19.7 Width: 8.25 Height: 9.15
    #   A - X: 101.5 Y: 20  Width: 8.25 Height: 9
    #
    it "extracts text correctly" do
      pending
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("Parallel Genetic Algorithms")
      end
    end
  end

  context "PDF with a Type0 font and Encoding is a CMap called OneByteIdentityH" do
    let(:filename) { pdf_spec_file("one-byte-identity") }

    # I'm not 100% confident that we'rr correctly handling OneByteIdentityH files in a way
    # that will always work. It works for the sample file I have though, so that's better than
    # nothing
    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("abc")
      end
    end
  end

  context "PDF with rotated text" do
    let(:filename) { pdf_spec_file("rotated_text") }

    # TODO this spec isn't ideal as our support for extracting rotated text is quite
    #      rubbish. I've added this to ensure we don't throw an exception with
    #      rotated text. It's a start.
    it "extracts text without raising an exception" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text.split("\n").map(&:strip).slice(0,2)).to eq(["°","9"])
      end
    end
  end

  context "PDF with a TJ operator that receives an array starting with a number" do
    let(:filename) { pdf_spec_file("TJ_starts_with_a_number") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text[0,18]).to eq("This file has a TJ")
      end
    end
  end

  context "PDF with a TJ operator that aims to correct for character spacing" do
    let(:filename) { pdf_spec_file("TJ_and_char_spacing") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text[15,17]).to eq("The big brown fox")
      end
    end
  end

  context "PDF with a page that's missing the MediaBox attribute" do
    let(:filename) { pdf_spec_file("mediabox_missing") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text[0,54]).to eq("This page is missing the compulsory MediaBox attribute")
      end
    end
  end

  context "PDF using a standard fint and no difference table" do
    let(:filename) { pdf_spec_file("standard_font_with_no_difference") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("This page uses contains a €")
      end
    end
  end

  context "PDF using zapf dingbats" do
    let(:filename) { pdf_spec_file("zapf") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("✄☎✇")
      end
    end
  end

  context "PDF using symbol text" do
    let(:filename) { pdf_spec_file("symbol") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("θρ")
      end
    end
  end

  context "Scanned PDF with invisible text added by ClearScan" do
    let(:filename) { pdf_spec_file("clearscan") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("This document was scanned and then OCRd with Adobe ClearScan")
      end
    end
  end

  context "PDF with text that contains a control char" do
    let(:filename) { pdf_spec_file("times-with-control-character") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("This text includes an ASCII control")
      end
    end
  end

  context "PDF where the top-level Pages object has no Type" do
    let(:filename) { pdf_spec_file("pages_object_missing_type") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("The top level Pages object has no Type")
      end
    end
  end

  context "PDF where the entries in a Kids array are direct objects, rather than indirect" do
    let(:filename) { pdf_spec_file("kids-as-direct-objects") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("page 1")
      end
    end
  end

  context "PDF with text positioned at 0,0" do
    let(:filename) { pdf_spec_file("minimal") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("Hello World")
      end
    end
  end

  context "Malformed PDF" do
    let(:filename) { pdf_spec_file("trailer_root_is_not_a_dict") }

    it "raises an exception if trailer Root is not a dict" do
      PDF::Reader.open(filename) do |reader|
        expect { reader.page(1) }.to raise_error(PDF::Reader::MalformedPDFError)
      end
    end
  end

  context "PDF with missing page data" do
    let(:filename) { pdf_spec_file("invalid_pages") }

    it "raises a MalformedPDFError when an InvalidPageError is raised internally" do
      PDF::Reader.open(filename) do |reader|
        expect { reader.pages }.to raise_error(PDF::Reader::MalformedPDFError)
      end
    end
  end

  context "PDF with MediaBox specified as an indirect object" do
    let(:filename) { pdf_spec_file("indirect_mediabox") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq("The MediaBox for this page is specified via an indirect object")
      end
    end
  end

  context "PDF with overlapping chars to achieve fake bold effect" do
    let(:filename) { pdf_spec_file("overlapping-chars-xy-fake-bold") }
    let(:text) {
      "Some characters that overlap with different X and Y to achieve a fake bold effect"
    }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq(text)
      end
    end
  end

  context "PDF with overlapping chars (same Y pos) to achieve fake bold effect" do
    let(:filename) { pdf_spec_file("overlapping-chars-x-fake-bold") }
    let(:text) {
      "Some characters that overlap with different X to achieve a fake bold effect"
    }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq(text)
      end
    end
  end

  context "PDF with 180 page rotation followed by matrix transformations to undo it" do
    let(:filename) { pdf_spec_file("rotate-180") }
    let(:text) {
      "This text is rendered upside down\nand then the page is rotated"
    }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq(text)
      end
    end
  end

  context "PDF with page rotation followed by matrix transformations to undo it" do
    let(:filename) { pdf_spec_file("rotate-then-undo") }
    let(:text) {
      "This page uses matrix transformations to print text sideways, " +
      "then has a Rotate key to fix it"
    }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq(text)
      end
    end
  end

  context "PDF with page rotation of 90 degrees followed by matrix transformations to undo it" do
    let(:filename) { pdf_spec_file("rotate-90-then-undo") }
    let(:text) {
      "1: This PDF has Rotate:90 in the page metadata\n" +
      "2: to get a landscape layout, and then uses matrix\n" +
      "3: transformation to rotate the text back to normal"
    }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to eq(text)
      end
    end
  end

  context "PDF with page rotation of 90 degrees followed by matrix transformations to undo it" do
    let(:filename) { pdf_spec_file("rotate-90-then-undo-with-br-text") }

    it "extracts text correctly" do
      PDF::Reader.open(filename) do |reader|
        page = reader.page(1)
        expect(page.text).to include("This PDF ha  sRotate:90 in the page")
        expect(page.text).to include("metadata to get a landscape layout")
        expect(page.text).to include("and text in bottom right quadrant")
      end
    end
  end
end
