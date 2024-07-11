# frozen_string_literal: true

module HttpZip
  module Parser
    # Parses the Central Directory File Header.
    class CentralDirectoryFileHeader
      ZIP64_EXTRA_FIELD_HEADER_ID = "\x01\x00"
      CENTRAL_DIRECTORY_FILE_HEADER_IDENTIFIER = "\x50\x4B\x01\x02"

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

      # Create a new instance of CentralDirectoryFileHeader.
      #
      # @param [String] file_header_bytes the byte string of the file header
      # @raises [ZipError] if byte string doesn't not represent a valid file header
      def initialize(file_header_bytes)
        @bytes = file_header_bytes
        unless @bytes.start_with?(CENTRAL_DIRECTORY_FILE_HEADER_IDENTIFIER)
          raise ZipError, "Central Directory File Header seems to be corrupt"
        end

        parse!
      end

      private

      # Parses the fields from the Central Directory File Header,
      # including data in Zip64 extra fields
      def parse!
        @compressed_size,
          @uncompressed_size,
          @file_name_length,
          @extra_field_length,
          @file_comment_length,
          @disk_number,
          @internal_file_attributes,
          @external_file_attributes,
          @header_offset = @bytes[20...46].unpack("VVvvvvvVV")

        file_name_end = 46 + file_name_length
        @file_name = @bytes[46...file_name_end]
        @end_of_entry = file_name_end + @extra_field_length + @file_comment_length

        # check if any of the values could not be represented by standard zip and will be stored in a
        # Zip64 extra field
        extra_field_bytes = @bytes[file_name_end...(file_name_end + @extra_field_length)]
        parse_zip64_extra_field_if_present!(extra_field_bytes)
      end

      # Parses the extra fields section of a Central Directory File Header in order to extract
      # the larger values for uncompressed size, compressed size, header offset, and disk number
      # of the ZIP file if they weren’t specified in the Central Directory File Header already.
      #
      # @param [String] full_extra_field_bytes the byte stream of the full extra fields
      #                 section of this Central Directory File Header
      def parse_zip64_extra_field_if_present!(full_extra_field_bytes)
        remaining_extra_field_bytes = full_extra_field_bytes
        until remaining_extra_field_bytes.empty?
          # zipalign might fill up the extra fields with all zero characters,
          # so we need to abort if there’s nothing of value in the extra fields
          break if remaining_extra_field_bytes.delete("\0").empty?

          record_length = remaining_extra_field_bytes[2...4].unpack1("v")

          # did we find the Zip64 extra field?
          if remaining_extra_field_bytes.start_with?(ZIP64_EXTRA_FIELD_HEADER_ID)
            read_values_from_extra_field_bytes!(remaining_extra_field_bytes[2..-1])
            break
          end

          total_extra_field_length = 2 + 2 + record_length
          remaining_extra_field_bytes = remaining_extra_field_bytes[total_extra_field_length..-1]
        end
      end

      # Sets values for uncompressed size, compressed size, header offset, and disk number
      # according to the values stored in the extra field.
      #
      # @param [String] extra_field_bytes the byte stream of the extra fields, starting right after
      #   the extra field header identifier
      def read_values_from_extra_field_bytes!(extra_field_bytes)
        # the zip64 extra field tries to store as little information as possible,
        # so only the values too large for the non-zip64 file header will be stored here
        ptr = 2 # ignore the size field, since it seems to be incorrect in some cases
        if @uncompressed_size == 0xFFFFFFFF
          @uncompressed_size = extra_field_bytes[ptr...(ptr + 8)].unpack1("Q<")
          ptr += 8
        end
        if @compressed_size == 0xFFFFFFFF
          @compressed_size = extra_field_bytes[ptr...(ptr + 8)].unpack1("Q<")
          ptr += 8
        end
        if @header_offset == 0xFFFFFFFF
          @header_offset = extra_field_bytes[ptr...(ptr + 8)].unpack1("Q<")
          ptr += 8
        end
        if @disk_number == 0xFFFF
          @disk_number = extra_field_bytes[ptr...(ptr + 4)].unpack1("V")
        end
      end
    end
  end
end
