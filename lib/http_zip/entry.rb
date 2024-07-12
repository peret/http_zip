# frozen_string_literal: true

module HttpZip
  # Describes one entry in an HTTP zip archive
  # @attr_reader [String] name filename of the entry
  class Entry
    attr_reader :name, :compressed_size, :uncompressed_size

    def initialize(url, name, header_offset, central_directory_file_compressed_size, central_directory_file_uncompressed_size)
      @range_request = HttpZip::RangeRequest.new(url)
      @name = name
      @header_offset = header_offset
      @compressed_size = central_directory_file_compressed_size
      @uncompressed_size = central_directory_file_uncompressed_size
    end

    # Get the decompressed content of the file entry
    # Makes 2 HTTP requests (GET, GET)
    def read
      # decompress the file
      from = @header_offset + header_size
      to = @header_offset + header_size + @compressed_size

      decompressor = compression_method
      compressed_contents = @range_request.get(from, to)
      decompressor.decompress(compressed_contents)
    end

    # Get the decompressed content of the file entry
    # Makes 2 HTTP requests (GET, GET)
    def write_to_file(filename)
      from = @header_offset + header_size
      to = @header_offset + header_size + @compressed_size

      decompressor = compression_method
      ::File.open(filename, "wb") do |out_file|
        @range_request.get(from, to) do |chunk|
          decompressed = decompressor.decompress(chunk)
          out_file.write(decompressed)
        end
        decompressor.finish
      end
    end

    private

    def header
      @header ||= @range_request.get(@header_offset, @header_offset + 30)
      @header
    end

    def header_size
      # find out where the file contents start and how large the file is
      file_name_length = header[26...28].unpack1("v")
      extra_field_length = header[28...30].unpack1("v")
      30 + file_name_length + extra_field_length
    end

    def compression_method
      # which compression method is used?
      algorithm = header[8...10].unpack1("v")

      case algorithm
      when 0
        HttpZip::Compression::Stored.new
      when 8
        HttpZip::Compression::Deflate.new
      else
        raise HttpZip::ZipError,
          "Unsupported compression method #{algorithm}. HttpZip only supports compression methods 0 (STORED) and 8 (DEFLATE)."
      end
    end
  end
end
