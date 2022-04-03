module HttpZip
  # 256x256 bytes is the maximum length of the EOCD comment,
  # 22 bytes is the remaining EOCD size
  # 20 bytes is the EOCD64 locator size
  MAXIMUM_EOCD_AND_EOCD64_LOCATOR_SIZE = (256 * 256) + 22 + 20
  EOCD64_SIZE_WITHOUT_COMMENT = 56

  # HttpZip reads ZIP-files over a HTTP connection that supports the Content-Range header.
  # It is a helpful tool to extract single files from large HTTP archives without having to
  # download them fully.
  #
  # Resources regarding the ZIP file format:
  # https://en.wikipedia.org/wiki/ZIP_(file_format)
  # https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
  class File
    # Create a HttpZip file object that is located at url.
    #
    # @param [String] url where the file is hosted
    def initialize(url)
      @url = url
      @entries = nil
      @range_request = RangeRequest.new(url)
    end

    # Get all entries in the zip archive as an array of HttpZip::Entry.
    # Makes up to 4 HTTP requests (HEAD, GET, GET, GET?)
    def entries
      return @entries if @entries

      @entries = []
      last_bytes_of_file = @range_request.last(MAXIMUM_EOCD_AND_EOCD64_LOCATOR_SIZE)
      central_directory_bytes = get_central_directory(last_bytes_of_file)

      # iterate through central directory and spit out file entries
      until central_directory_bytes.empty?
        # get information about the current file entry
        file_header = HttpZip::Parser::CentralDirectoryFileHeader.new(central_directory_bytes)
        @entries << HttpZip::Entry.new(
          @url,
          file_header.file_name,
          file_header.header_offset,
          file_header.compressed_size
        )

        # skip ahead to next file entry
        central_directory_bytes = central_directory_bytes[(file_header.end_of_entry)..-1]
      end

      @entries
    end

    private

    # The central directory contains all file names within the archive as well as
    # their offsets to the beginning of the archive file.
    # Get the whole central directory so the client can traverse it and find the
    # file entry they are looking for.
    #
    # makes 1 GET request for non-Zip64 files, 2 GET requests for Zip64 files
    def get_central_directory(last_bytes_of_file)
      central_directory = HttpZip::Parser::CentralDirectory.new(last_bytes_of_file)
      if central_directory.eocd64_offset
        # This is a Zip64 archive, so parse the EOCD64 block to find out where the central directory
        # is located
        eocd64_block = @range_request.get(
          central_directory.eocd64_offset,
          central_directory.eocd64_offset + EOCD64_SIZE_WITHOUT_COMMENT
        )
        central_directory.parse_eocd64!(eocd64_block)
      end

      # get the actual central directory
      central_directory_end = central_directory.offset + central_directory.size
      @range_request.get(central_directory.offset, central_directory_end)
    end
  end
end
