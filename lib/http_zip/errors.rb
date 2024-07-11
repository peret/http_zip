# frozen_string_literal: true

module HttpZip
  class Error < StandardError; end

  class RequestError < Error; end

  class ContentRangeError < RequestError; end

  class ZipError < Error; end
end
