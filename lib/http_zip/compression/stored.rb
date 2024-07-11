# frozen_string_literal: true

module HttpZip
  module Compression
    class Stored
      def decompress(input)
        input
      end

      def finish
      end
    end
  end
end
