$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "http_zip"

require "minitest/autorun"
require 'webmock/minitest'

class MiniTest::Test
  def read_range(file, range)
    match = /bytes=(\d+)?-(\d+)/.match(range)
    if match[1].nil?
      # read until end of file
      length = [match[2].to_i, file.size].min
      file.seek(-length, IO::SEEK_END)
      file.read
    else
      # read from offset
      from = match[1].to_i
      to = match[2].to_i
      length = (to - from) + 1
      file.seek(from)
      file.read(length)
    end
  end
end