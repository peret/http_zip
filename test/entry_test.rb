# frozen_string_literal: true

require "test_helper"

module HttpZip
  class EntryTest < Minitest::Test
    def test_it_throws_when_encountering_unsupported_compression_method
      url = "http://example.com/file.zip"
      name = "file.txt"
      header_offset = 10
      central_directory_file_compressed_size = 128
      entry = HttpZip::Entry.new(url, name, header_offset, central_directory_file_compressed_size)

      compression_method = 1
      file_name_length = name.length
      extra_field_length = 0
      stubbed_header = [0, compression_method, 0, 0, file_name_length,
        extra_field_length].pack("QvQQvv")
      entry.stub :header, stubbed_header do
        assert_raises HttpZip::ZipError do
          entry.read
        end
      end
    end
  end
end
