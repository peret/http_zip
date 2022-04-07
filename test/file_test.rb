# frozen_string_literal: true

require 'test_helper'

module HttpZip
  class FileTest < Minitest::Test
    def setup
      @url = 'http://example.com/file.zip'
      @extracted_file_path = ::File.join(__dir__, 'fixtures', 'files',
                                         '886c5960-5345-48f0-bf3c-9fd5145a62aa.jpg')
      @extracted_file = ::File.open(@extracted_file_path, 'rb')
    end

    def test_it_throws_when_server_responds_with_a_non_partial_response
      mock_content_range_head_request
      stub_request(:get, @url).to_return(status: 200, body: '')
      assert_raises HttpZip::ContentRangeError do
        HttpZip::File.new(@url).entries
      end
    end

    def test_it_throws_when_server_does_not_support_content_range
      stub_request(:head, @url).to_return(
        status: 200,
        body: '',
        headers: { 'Accept-Ranges' => 'none' }
      )
      assert_raises HttpZip::ContentRangeError do
        HttpZip::File.new(@url)
      end
    end

    def test_it_throws_when_server_does_not_specify_content_range_support
      stub_request(:head, @url).to_return(
        status: 200,
        body: ''
      )
      assert_raises HttpZip::ContentRangeError do
        HttpZip::File.new(@url)
      end
    end

    def test_it_gets_the_zip_entries_and_reads_them
      path = ::File.join(__dir__, 'fixtures', 'files', 'dogs.zip')
      zip_file = ::File.open(path, 'rb')

      mock_range_request(@url, zip_file)
      http_entries = HttpZip::File.new(@url).entries
      assert_equal 7, http_entries.length
      http_entry = http_entries.last
      http_entry.write_to_file('./test/test.jpg')
      assert @extracted_file.read == http_entry.read, "Extracted files don't match"
    end

    def test_it_gets_the_zip_entries_and_reads_them_for_a_zip64_archive
      zip64_path = ::File.join(__dir__, 'fixtures', 'files', 'dogs64.zip')
      zip64_file = ::File.open(zip64_path, 'rb')

      mock_range_request(@url, zip64_file)
      http_entries = HttpZip::File.new(@url).entries
      assert_equal 7, http_entries.length
      http_entry = http_entries.last
      assert @extracted_file.read == http_entry.read, "Extracted files don't match"
    end

    def test_it_gets_the_zip_entries_and_reads_stored_files
      stored_zip_path = ::File.join(__dir__, 'fixtures', 'files', 'dogs_stored.zip')
      stored_zip_file = ::File.open(stored_zip_path, 'rb')

      mock_range_request(@url, stored_zip_file)
      http_entries = HttpZip::File.new(@url).entries
      assert_equal 7, http_entries.length
      http_entry = http_entries.last
      assert @extracted_file.read == http_entry.read, "Extracted files don't match"
    end
  end
end
