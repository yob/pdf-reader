# typed: false
# coding: utf-8

require 'yaml'

# This spec just checks that the PDFs in the spec suite are intact.
#
# If the PDFs have been modified in some way (like git mangling the
# line endings) then specs wil fail in confusing ways.
#
# This spec will fail if a new PDF is added to the suite but not
# listed in spec/integrity.yml. After adding the new PDF, be sure to
# run 'rake integrity_yaml'

describe "Spec suite PDFs" do
  it "should be intact" do
    yaml_path = File.expand_path("integrity.yml",File.dirname(__FILE__))
    pdfs_path = File.expand_path("data/**/**.pdf",File.dirname(__FILE__))
    integrity = YAML.load_file(yaml_path)

    Dir.glob(pdfs_path).each do |path|
      relative_path = path[/.+(data\/.+)/,1]
      item = integrity[relative_path]

      # every PDF in the suite MUST be included in the integrity file
      expect(item).not_to be_nil, "#{path} not found in integrity YAML file"

      # every PDF in the suite MUST be the correct number of bytes
      expect(File.size(path)).to eql(item[:bytes])

      # every PDF in the suite MUST be unchanged
      md5 = Digest::MD5.hexdigest(File.open(path, "rb") { |f|  f.read })
      expect(md5).to eq(item[:md5])
    end
  end
end
