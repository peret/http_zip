# frozen_string_literal: true

module HttpZip
  module Compression
    class Deflate
      def initialize
        @inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      end

      def decompress(input)
        @inflater.inflate(input)
      end

      def finish
        @inflater.finish
        @inflater.close
      end
    end
  end
end
