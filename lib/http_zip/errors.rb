module HttpZip
  class Error < StandardError; end
  class ContentRangeError < Error; end
  class ZipError < Error; end
end
