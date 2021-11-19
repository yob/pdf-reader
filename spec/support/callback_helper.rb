# typed: true
# coding: utf-8

class CallbackHelper
  include Singleton

  def good_receivers
    @registers ||= {}
    if @registers.empty?
      good_files.map { |filename|
        receiver = PDF::Reader::RegisterReceiver.new
        PDF::Reader.open(filename) do |reader|
          reader.pages.each do |page|
            page.walk(receiver)
          end
        end
        @registers[filename] = receiver
      }
    end
    @registers
  end

  private

  def good_files
    @good_files ||= Dir.glob(File.dirname(__FILE__) + "/../data/*.pdf").select { |filename|
      !filename.include?("screwey_xref_offsets") &&
        !filename.include?("difference_table_encrypted") &&
        !filename.include?("broken_string.pdf") &&
        !filename.include?("cross_ref_stream.pdf") &&
        !filename.include?("zlib_stream_issue.pdf") &&
        !filename.include?("20070313") &&
        !filename.include?("refers_to_invalid_font.pdf") &&
        !filename.include?("encrypted") &&
        !filename.include?("junk_prefix")
    }
  end

end
