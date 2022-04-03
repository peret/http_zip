# HttpZip

HttpZip is a Ruby gem to extract individual files from a remote ZIP archive, without the need to download the entire file.

If your Zip file is hosted on a server that supports Content-Range requests and you only want to extract individual files, you don't need to download
the entire archive to do that. HttpZip uses Content-Range requests to first read only the Central Directory of your archive and builds a list of entries
from that. You can then download and extract individual entries without downloading the entire archive.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'http_zip'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install http_zip

## Usage

```ruby
# Create a new HttpZip::File referencing your remote archive.
# This only makes a HEAD request to check the server for
# Range request support.
zip = HttpZip::File.new("https://www.example.org/archive.zip")

# Get a reference to a specific file.
# This only requests the archive's Central Directory Entry.
entry = zip.entries.find { |e| e.name == 'compressed.txt' }

# Read the extracted file contents into memory.
# This downloads the entry's compressed contents and uncompresses
# them locally.
content = entry.read
# You can also write the extracted entry directly to a local file.
entry.write_to_file('/path/extracted.txt')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/peret/http_zip.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
