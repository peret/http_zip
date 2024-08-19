# frozen_string_literal: true

require "test_helper"

module HttpZip
  class CentralDirectoryTest < Minitest::Test
    def test_it_finds_the_end_of_central_directory
      filler = "\x01" * 10
      signature = "\x50\x4B\x05\x06"
      padding = "\x00" * 8
      size = "\x0f\x00\x00\x00" # decimal 15
      offset = "\x1f\x00\x00\x00" # decimal 31
      comment_length = "\x00\x00"

      bytes = "#{filler}#{signature}#{padding}#{size}#{offset}#{comment_length}"

      central_directory = Parser::CentralDirectory.new(bytes)
      assert_equal 15, central_directory.size
      assert_equal 31, central_directory.offset
    end

    def test_it_ignores_additional_data_at_the_end_when_finding_the_end_of_central_directory
      filler = "\x01" * 10
      signature = "\x50\x4B\x05\x06"
      padding = "\x00" * 8
      size = "\x0f\x00\x00\x00" # decimal 15
      offset = "\x1f\x00\x00\x00" # decimal 31
      comment_length = "\x00\x00"

      bytes = "#{filler}#{signature}#{padding}#{size}#{offset}#{comment_length}#{filler}"

      central_directory = Parser::CentralDirectory.new(bytes)
      assert_equal 15, central_directory.size
      assert_equal 31, central_directory.offset
    end
  end
end
