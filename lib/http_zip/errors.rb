module HttpZip
  class Error < StandardError; end
  class ServerDoesNotSupportContentRange < Error; end
  class CannotLocateEocdBlock < Error; end
  class CentralDirectoryCorrupt < Error; end
  class UnsupportedCompressionMethod < Error; end
end
