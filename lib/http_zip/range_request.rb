# frozen_string_literal: true

require 'httparty'

module HttpZip
  # Class to make Range requests to a HTTP server
  class RangeRequest
    # Create a new RangeRequest object
    #
    # @param [String] url remote file URL
    def initialize(url)
      @url = url
    end

    # Request a partial object via HTTP. If a block is given, yields the response body in chunks.
    #
    # @param [Integer] from start byte of the range to request. Inclusive.
    # @param [Integer] to end byte of the range to request. Exclusive.
    # @yield [chunk] yields a chunk of data to the block
    # @raise [ContentRangeError] if the server responds with anything other than 206 Partial Content
    def get(from, to)
      options = { headers: { 'Range' => "bytes=#{from}-#{to - 1}" } }
      options[:stream_body] = true if block_given?

      response = HTTParty.get(@url, options) do |chunk|
        yield chunk if block_given?
      end

      if response.code != 206
        # oops, we downloaded the whole file
        raise ContentRangeError, 'Server does not support the Range header'
      end

      response.body
    end

    # Request the last `num_bytes` bytes of the remote file via HTTP.
    #
    # @param [Integer] num_bytes number of bytes to request
    # @raise [ContentRangeError] if the server responds with anything other than 206 Partial Content
    def last(num_bytes)
      response = HTTParty.get(@url, headers: { 'Range' => "bytes=-#{num_bytes}" })
      if response.code != 206
        # oops, we downloaded the whole file
        raise ContentRangeError, 'Server does not support the Range header'
      end

      response.body
    end

    # Tests if the server supports the Range header by checking the "Accept-Ranges" header,
    # otherwise raises an exception.
    #
    # @raise [ContentRangeError] if the server does not support the Range header
    def check_server_supports_content_range!
      return if self.class.server_supports_content_range?(@url)

      raise ContentRangeError, 'Server does not support the Range header'
    end

    # Tests if the server supports the Range header by checking the "Accept-Ranges" header.
    #
    # @param [String] url remote file URL
    # @return [Boolean] true if the server supports the Range header
    def self.server_supports_content_range?(url)
      response = HTTParty.head(url)
      response.headers['Accept-Ranges'] && response.headers['Accept-Ranges'].downcase != 'none'
    end
  end
end
