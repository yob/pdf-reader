# typed: false
# coding: utf-8

require 'openssl'

describe PDF::Reader::AesV3SecurityHandler do
  let(:key) { "a" * 32 } # exactly 32 bytes for AES-256
  let(:handler) { PDF::Reader::AesV3SecurityHandler.new(key) }
  let(:reference) { PDF::Reader::Reference.new(1, 0) }

  describe "#initialize" do
    context "with valid 32-byte key" do
      it "creates handler successfully" do
        expect { PDF::Reader::AesV3SecurityHandler.new("a" * 32) }.not_to raise_error
      end
    end

    context "with invalid key lengths" do
      it "raises MalformedPDFError for short key" do
        expect {
          PDF::Reader::AesV3SecurityHandler.new("short")
        }.to raise_error(
          PDF::Reader::MalformedPDFError, "AES-256 key must be exactly 32 bytes, got 5"
        )
      end

      it "raises MalformedPDFError for long key" do
        expect {
          PDF::Reader::AesV3SecurityHandler.new("a" * 40)
        }.to raise_error(
          PDF::Reader::MalformedPDFError, "AES-256 key must be exactly 32 bytes, got 40"
        )
      end

      it "raises MalformedPDFError for empty key" do
        expect {
          PDF::Reader::AesV3SecurityHandler.new("")
        }.to raise_error(
          PDF::Reader::MalformedPDFError, "AES-256 key must be exactly 32 bytes, got 0"
        )
      end
    end
  end

  describe "#decrypt" do
    context "with ciphertext that is not a multiple of 16 bytes" do
      it "raises MalformedPDFError" do
        invalid_buf = "short"
        expect {
          handler.decrypt(invalid_buf, reference)
        }.to raise_error(PDF::Reader::MalformedPDFError, "Ciphertext not a multiple of 16")
      end
    end

    context "with exactly 16 bytes (IV only)" do
      it "returns empty string" do
        iv_only = "0123456789abcdef"
        result = handler.decrypt(iv_only, reference)
        expect(result).to eq("")
      end
    end

    context "with valid padded ciphertext" do
      it "decrypts successfully with PKCS#7 padding" do
        plaintext = "Hello, World!"
        buf = encrypt_test_data(plaintext, key, padding: true)

        result = handler.decrypt(buf, reference)
        expect(result).to eq(plaintext)
      end
    end

    context "with ciphertext without padding and valid key" do
      it "should decrypt successfully with no padding" do
        plaintext = "1234567890123456" # exactly 16 bytes
        buf = encrypt_test_data(plaintext, key, padding: false)

        result = handler.decrypt(buf, reference)
        expect(result).to eq(plaintext)
      end
    end

    context "with ciphertext without padding and invalid key" do
      it "returns incorrect data when key is wrong" do
        wrong_key = "b" * 32 # different 32-byte key
        wrong_handler = PDF::Reader::AesV3SecurityHandler.new(wrong_key)

        plaintext = "1234567890123456"
        buf = encrypt_test_data(plaintext, key, padding: false)

        # Try to decrypt with wrong key - should return garbage, not raise error
        result = wrong_handler.decrypt(buf, reference)
        expect(result).not_to eq(plaintext)
        expect(result).to be_a(String)
      end
    end

    context "with padded ciphertext and invalid key" do
      it "returns incorrect data when key is wrong" do
        wrong_key = "b" * 32 # different 32-byte key
        wrong_handler = PDF::Reader::AesV3SecurityHandler.new(wrong_key)

        plaintext = "Hello, World!"
        buf = encrypt_test_data(plaintext, key, padding: true)

        # Try to decrypt with wrong key - should return garbage, not raise error
        result = wrong_handler.decrypt(buf, reference)
        expect(result).not_to eq(plaintext)
        expect(result).to be_a(String)
      end
    end

    context "with malformed ciphertext" do
      it "returns a string with garbage content" do
        # Create invalid ciphertext with proper 32-byte key handler
        iv = "0123456789abcdef"
        corrupted_data = "corrupted_data16" # exactly 16 bytes
        buf = iv + corrupted_data

        result = handler.decrypt(buf, reference)
        expect(result).to be_a(String)
      end
    end
  end

  private

  # Helper method to create encrypted test data for AES-V3
  # @param plaintext [String] the text to encrypt
  # @param encryption_key [String] the encryption key to use (32 bytes for AES-256)
  # @param padding [Boolean] whether to use PKCS#7 padding
  # @return [String] IV + ciphertext ready for decrypt method
  def encrypt_test_data(plaintext, encryption_key, padding: true)
    # AES-V3 uses the key directly without object reference modification
    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.padding = 0 unless padding
    cipher.key = encryption_key.dup
    iv = cipher.random_iv
    ciphertext = cipher.update(plaintext) + cipher.final

    # Return IV + ciphertext for the handler
    iv + ciphertext
  end
end
