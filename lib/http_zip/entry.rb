# frozen_string_literal: true

module HttpZip
  # Describes one entry in an HTTP zip archive
  class Entry
    attr_reader :name

    def initialize(url, name, header_offset, central_directory_file_compressed_size)
      @range_request = HttpZip::RangeRequest.new(url)
      @name = name
      @header_offset = header_offset
      @compressed_size = central_directory_file_compressed_size
    end

    # Get the decompressed content of the file entry
    # Makes 2 HTTP requests (GET, GET)
    def read
      # decompress the file
      from = @header_offset + header_size
      to = @header_offset + header_size + @compressed_size

      decompress, _finish = decompress_funcs

      compressed_contents = @range_request.get(from, to)
      decompress.call(compressed_contents)
    end

    # Get the decompressed content of the file entry
    # Makes 2 HTTP requests (GET, GET)
    def write_to_file(filename)
      from = @header_offset + header_size
      to = @header_offset + header_size + @compressed_size

      decompress, finish = decompress_funcs

      ::File.open(filename, 'wb') do |out_file|
        @range_request.get(from, to) do |chunk|
          decompressed = decompress.call(chunk)
          out_file.write(decompressed)
        end
        finish.call
      end
    end

    private

    def header
      @header ||= @range_request.get(@header_offset, @header_offset + 30)
      @header
    end

    def header_size
      # find out where the file contents start and how large the file is
      file_name_length = header[26...28].unpack1('v')
      extra_field_length = header[28...30].unpack1('v')
      30 + file_name_length + extra_field_length
    end

    def decompress_funcs
      # which compression method is used?
      compression_method = header[8...10].unpack1('v')

      case compression_method
      when 0
        # STORED content, doesn't require decompression
        decompress = lambda { |input|
          input
        }
        finish = -> {}
      when 8
        inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
        # DEFLATED content, inflate it
        decompress = lambda { |input|
          inflater.inflate(input)
        }
        finish = lambda do
          inflater.finish
          inflater.close
        end
      else
        raise HttpZip::ZipError,
              "Unsupported compression method #{compression_method}. HttpZip only supports compression methods 0 (STORED) and 8 (DEFLATE)."
      end

      [decompress, finish]
    end
  end
end
