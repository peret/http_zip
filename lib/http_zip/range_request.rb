require 'httparty'

module HttpZip
  class RangeRequest
    def initialize(url)
      @url = url
    end

    # Request a partial object via HTTP. from is inclusive, to is noninclusive.
    # Raise if `Range` header is not supported.
    def get(from, to)
      options = { headers: { 'Range' => "bytes=#{from}-#{to - 1}" } }
      options[:stream_body] = true if block_given?

      response = HTTParty.get(@url, options) do |chunk|
        yield chunk if block_given?
      end

      if response.code != 206
        # oops, we downloaded the whole file
        raise ServerDoesNotSupportContentRange, 'Server does not support the Range header'
      end

      response.body
    end

    # Get the last `num_bytes` bytes via HTTP.
    # Raise if `Range` header is not supported.
    def last(num_bytes)
      response = HTTParty.get(@url, headers: { 'Range' => "bytes=-#{num_bytes}" })
      if response.code != 206
        # oops, we downloaded the whole file
        raise ServerDoesNotSupportContentRange, 'Server does not support the Range header'
      end

      response.body
    end

    def check_server_supports_content_range!
      return if self.class.server_supports_content_range?(@url)

      raise ServerDoesNotSupportContentRange, 'Server does not support the Range header'
    end

    def self.server_supports_content_range?(url)
      response = HTTParty.head(url)
      response.headers['Accept-Ranges'] && response.headers['Accept-Ranges'].downcase != 'none'
    end
  end
end
