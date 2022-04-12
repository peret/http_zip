# frozen_string_literal: true

require 'net/http'

module HttpZip
  # Class to make Range requests to a HTTP server
  class RangeRequest
    # Create a new RangeRequest object
    #
    # @param [String] url remote file URL
    def initialize(url)
      @uri = URI(url)
      @connection = Net::HTTP.new(@uri.host, @uri.port)
      @connection.use_ssl = true if @uri.scheme == 'https'
    end

    # Request a partial object via HTTP. If a block is given, yields the response body in chunks.
    #
    # @param [Integer] from start byte of the range to request. Inclusive.
    # @param [Integer] to end byte of the range to request. Exclusive.
    # @yield [chunk] yields a chunk of data to the block
    # @raise [ContentRangeError] if the server responds with anything other than 206 Partial Content
    def get(from, to, &block)
      request = Net::HTTP::Get.new(@uri)
      request['Range'] = "bytes=#{from}-#{to - 1}"
      make_request(request, &block)
    end

    # Request the last `num_bytes` bytes of the remote file via HTTP.
    #
    # @param [Integer] num_bytes number of bytes to request
    # @raise [ContentRangeError] if the server responds with anything other than 206 Partial Content
    def last(num_bytes)
      request = Net::HTTP::Get.new(@uri)
      request['Range'] = "bytes=-#{num_bytes}"
      make_request(request)
    end

    private

    def make_request(request, &block)
      @connection.start do |http|
        response = http.request(request) do |res|
          handle_response_code!(res)
          res.read_body(&block)
        end

        response.body unless block_given?
      end
    end

    def handle_response_code!(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise RequestError, "Server responded with #{response.code} #{response.message}"
      end
      return if response.is_a?(Net::HTTPPartialContent)

      raise ContentRangeError, 'Server does not support the Range header'
    end
  end
end
