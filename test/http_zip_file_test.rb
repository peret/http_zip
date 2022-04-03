require 'test_helper'

class HttpZipFileTest < Minitest::Test
  def setup
    @url = 'http://example.com/file.zip'
    path = File.join(__dir__, 'fixtures', 'files', 'dogs.zip')
    @file = File.open(path, 'rb')
    @extracted_file_path = File.join(__dir__, 'fixtures', 'files', '886c5960-5345-48f0-bf3c-9fd5145a62aa.jpg')
    @extracted_file = File.open(@extracted_file_path, 'rb')

    @zip64_url = 'http://example.com/file64.zip'
    zip64_path = File.join(__dir__, 'fixtures', 'files', 'dogs64.zip')
    @zip64_file = File.open(zip64_path, 'rb')
  end

  def test_it_throws_when_server_does_not_support_content_range
    stub_request(:get, @url).to_return(status: 200, body: '')
    assert_raises HttpZip::ServerDoesNotSupportContentRange do
      HttpZip::File.new(@url).entries
    end
  end

  def test_it_gets_the_zip_entries_and_reads_them
    stub_request(:get, @url).to_return do |request|
      range = request.headers['Range']
      if range.empty?
        { status: 200, body: '' }
      else
        { status: 206, body: read_range(@file, range) }
      end
    end
    http_entries = HttpZip::File.new(@url).entries
    assert_equal 7, http_entries.length
    http_entry = http_entries.last
    http_entry.write_to_file('./test/test.jpg')
    assert @extracted_file.read == http_entry.read, "Extracted files don't match"
  end

  def test_it_gets_the_zip_entries_and_reads_them_for_a_zip64_archive
    stub_request(:get, @zip64_url).to_return do |request|
      range = request.headers['Range']
      if range.empty?
        { status: 200, body: '' }
      else
        { status: 206, body: read_range(@zip64_file, range) }
      end
    end
    http_entries = HttpZip::File.new(@zip64_url).entries
    assert_equal 7, http_entries.length
    http_entry = http_entries.last
    assert @extracted_file.read == http_entry.read, "Extracted files don't match"
  end
end
