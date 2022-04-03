module HttpZip
  module Parser
    class CentralDirectoryFileHeader
      ZIP64_EXTRA_FIELD_HEADER_ID = "\x01\x00".freeze
      CENTRAL_DIRECTORY_FILE_HEADER_IDENTIFIER = "\x50\x4B\x01\x02".freeze

      attr_reader(
        :compressed_size,
        :uncompressed_size,
        :file_name_length,
        :extra_field_length,
        :file_comment_length,
        :disk_number,
        :internal_file_attributes,
        :external_file_attributes,
        :header_offset,
        :file_name,
        :end_of_entry
      )

      def initialize(file_header_bytes)
        @bytes = file_header_bytes
        unless @bytes.start_with?(CENTRAL_DIRECTORY_FILE_HEADER_IDENTIFIER)
          raise CentralDirectoryCorrupt, 'Central Directory File Header seems to be corrupt'
        end

        parse!
      end

      private

      def parse!
        @compressed_size,
          @uncompressed_size,
          @file_name_length,
          @extra_field_length,
          @file_comment_length,
          @disk_number,
          @internal_file_attributes,
          @external_file_attributes,
          @header_offset = @bytes[20...46].unpack('VVvvvvvVV')

        file_name_end = 46 + file_name_length
        @file_name = @bytes[46...file_name_end]
        @end_of_entry = file_name_end + @extra_field_length + @file_comment_length

        # check if any of the values could not be represented by standard zip and will be stored in a
        # Zip64 extra field
        extra_field_bytes = @bytes[file_name_end...(file_name_end + @extra_field_length)]
        parse_zip64_extra_field_if_present!(extra_field_bytes)
      end

      # Parses the extra fields section of a local file header in order to extract
      # the larger values for uncompressed size, compressed size and header offset
      # of the ZIP file if they weren’t specified in the local file header already
      #
      # @param [String] full_extra_field_bytes the byte stream of the full extra fields
      #                 section of this local file header
      # @param [Integer] uncompressed_size as extracted from the local file header
      # @param [Integer] compressed_size as extracted from the local file header
      # @param [Integer] header_offset as extracted from the local file header
      #
      # @return [[uncompressed_size, compressed_size, header_offset]] either as it was passed, or, if it
      #         could successfully be parsed from there, from the zip64 extra field
      def parse_zip64_extra_field_if_present!(full_extra_field_bytes)
        remaining_extra_field_bytes = full_extra_field_bytes
        until remaining_extra_field_bytes.empty? do
          # zipalign might fill up the extra fields with all zero characters,
          # so we need to abort if there’s nothing of value in the extra fields
          break if remaining_extra_field_bytes.delete("\0").empty?

          record_length = remaining_extra_field_bytes[2...4].unpack1('v')

          # did we find the Zip64 extra field?
          if remaining_extra_field_bytes.start_with?(ZIP64_EXTRA_FIELD_HEADER_ID)
            # the zip64 extra field tries to store as little information as possible,
            # so only the values too large for the non-zip64 file header will be stored here

            ptr = 4
            if @uncompressed_size == 0xFFFFFFFF
              @uncompressed_size = remaining_extra_field_bytes[ptr...(ptr + 8)].unpack1('Q<')
              ptr += 8
            end
            if @compressed_size == 0xFFFFFFFF
              @compressed_size = remaining_extra_field_bytes[ptr...(ptr + 8)].unpack1('Q<')
              ptr += 8
            end
            if @header_offset == 0xFFFFFFFF
              @header_offset = remaining_extra_field_bytes[ptr...(ptr + 8)].unpack1('Q<')
              ptr += 8
            end
            if @disk_number == 0xFFFF
              @disk_number = remaining_extra_field_bytes[ptr...(ptr + 4)].unpack1('V')
            end
            break
          end

          total_extra_field_length = 2 + 2 + record_length
          remaining_extra_field_bytes = remaining_extra_field_bytes[total_extra_field_length..-1]
        end
      end
    end
  end
end
