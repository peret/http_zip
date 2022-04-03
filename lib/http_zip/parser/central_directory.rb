module HttpZip
  module Parser
    class CentralDirectory
      EOCD_BLOCK_IDENTIFIER = "\x50\x4B\x05\x06".freeze
      EOCD64_LOCATOR_BLOCK_IDENTIFER = "\x50\x4b\x06\x07".freeze
      EOCD64_BLOCK_IDENTIFER = "\x50\x4b\x06\x06".freeze

      attr_reader :size, :offset, :eocd64_offset

      def initialize(end_of_central_directory_bytes)
        @bytes = end_of_central_directory_bytes

        parse!
      end

      def parse_eocd64!(eocd64_block)
        unless eocd64_block.start_with?(EOCD64_BLOCK_IDENTIFER)
          raise CannotLocateEocdBlock, 'I thought this should be the EOCD64 record, but it is not'
        end

        @size, @offset = eocd64_block[40..-1].unpack('Q<Q<')
      end

      private

      def parse!
        eocd_block_index = get_eocd_block_index(@bytes)
        eocd_block = @bytes[eocd_block_index..-1]
        @size, @offset = eocd_block[12...20].unpack('VV')
        return if @size != 0xFFFFFFFF && @offset != 0xFFFFFFFF

        # there will be a zip64 EOCD locator block before the EOCD block
        # parse the EOCD locator to find out where the EOCD64 block starts
        eocd64_locator_block = @bytes[(eocd_block_index - 20)..eocd_block_index]
        unless eocd64_locator_block.start_with?(EOCD64_LOCATOR_BLOCK_IDENTIFER)
          raise CannotLocateEocdBlock, 'Could not locate the EOCD64 locator block'
        end

        @eocd64_offset, total_num_disks = eocd64_locator_block[8..-1].unpack('Q<V')
        return if total_num_disks == 1

        raise CannotLocateEocdBlock, 'Multi-disk archives are not supported'
      end

      # In order to find the central directory, we have to first find the EOCD block.
      # The EOCD block (End Of Central Directory) identifies the end of the central directory
      # of the zip file and contains the offset where the central directory is located and its length.
      # The EOCD block is always at the end of the file.
      def get_eocd_block_index(last_bytes_of_file)
        # From the end of the file, get the maximum amount of bytes the EOCD block can have
        candidate_eocd_block = last_bytes_of_file

        # Scan the downloaded bytes from right to left to find the magic EOCD
        # block identifier
        eocd_block_start_index = nil
        search_end_position = candidate_eocd_block.length
        loop do
          eocd_block_start_index = candidate_eocd_block.rindex(EOCD_BLOCK_IDENTIFIER, search_end_position)

          if eocd_block_start_index.nil?
            raise CannotLocateEocdBlock, 'Could not locate valid EOCD block'
          end

          # we have a candidate, verify that we found the actual eocd block start by
          # checking whether its position + length matches the end of the file
          comment_length = candidate_eocd_block[(eocd_block_start_index + 20)...(eocd_block_start_index + 22)].unpack1('v')
          if (eocd_block_start_index + 22 + comment_length) == candidate_eocd_block.length
            # we found it
            break
          end

          search_end_position = eocd_block_start_index
        end

        eocd_block_start_index
      end
    end
  end
end
