require 'net/https'

class RedirectFollower
  class TooManyRedirects < StandardError; end

  attr_accessor :url, :body, :redirect_limit, :response

  def initialize(url, limit = 5, options = {})
    if limit.is_a? Hash
      options = limit
      limit = 5
    end
    @url, @redirect_limit = url, limit
    @headers = options[:headers]
  end

  def resolve
    raise TooManyRedirects if redirect_limit < 0

    uri = URI.parse(URI.escape(url))
    if uri.scheme == 'https'
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    else
      http = Net::HTTP.new(uri.host, uri.port)
    end
    self.response = http.request_get(uri.request_uri, @headers)

    if response.kind_of?(Net::HTTPRedirection)
      self.url = redirect_url
      self.redirect_limit -= 1
      resolve
    end

    self.body = response.body
    self
  end

  def redirect_url
    if response['location'].nil?
      response.body.match(/<a href=\"([^>]+)\">/i)[1]
    else
      response['location']
    end
  end
end
