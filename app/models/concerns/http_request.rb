class HttpRequest
  def initialize(url)
  	@uri = URI.parse(url)
  end

  def get
  	Net::HTTP.get(@uri)
  end
end