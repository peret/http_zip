# 2.1.0
* Add getters for each entry's compressed and uncompressed size (#1).

# 2.0.0
* Drop dependency on HTTParty
* Remove `RangeRequest.server_supports_content_range?` and `RangeRequest.check_server_supports_content_range!`
* Instead of pre-checking for Range request support, we just attempt the request and abort it early if the server doesn't support Range requests. This should make it more reliable for servers that e.g. don't announce support with the Accept-Ranges header or don't support HEAD requests.
* Better separation of server error responses: When the server responds with an error, HttpZip now raises `HttpZip::RequestError`. Only when the response is successful, but not `206 Partial Content`, do we raise `HttpZip::ContentRangeError`.

# 1.0.0
* Initial release
