# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'simplecov'
SimpleCov.start

require 'http_zip'

require 'minitest/autorun'
require 'webmock/minitest'

module MiniTest
  class Test
    def mock_content_range_head_request
      stub_request(:head, @url).to_return(
        status: 200,
        body: '',
        headers: { 'Accept-Ranges' => 'bytes' }
      )
    end

    def mock_range_request(url, file)
      mock_content_range_head_request
      stub_request(:get, url).to_return do |request|
        range = request.headers['Range']
        if range.empty?
          { status: 200, body: '' }
        else
          { status: 206, body: read_range(file, range) }
        end
      end
    end

    def read_range(file, range)
      match = /bytes=(\d+)?-(\d+)/.match(range)
      if match[1].nil?
        # read until end of file
        length = [match[2].to_i, file.size].min
        file.seek(-length, IO::SEEK_END)
        file.read
      else
        # read from offset
        from = match[1].to_i
        to = match[2].to_i
        length = (to - from) + 1
        file.seek(from)
        file.read(length)
      end
    end
  end
end
