class PawooApiClient
  extend Memoist

  class MissingConfigurationError < Exception ; end

  class Account
    attr_reader :json

    def self.is_match?(url)
      url =~ %r!https?://pawoo.net/web/accounts/(\d+)!
      $1
    end

    def initialize(json)
      @json = json
    end

    def profile_url
      json["url"]
    end

    def account_name
      json["username"]
    end

    def image_url
      nil
    end

    def image_urls
      []
    end

    def tags
      []
    end

    def commentary
      nil
    end
  end

  class Status
    attr_reader :json

    def self.is_match?(url)
      url =~ %r!https?://pawoo.net/web/statuses/(\d+)! || url =~ %r!https?://pawoo.net/@.+?/(\d+)!
      $1
    end

    def initialize(json)
      @json = json
    end

    def profile_url
      json["account"]["url"]
    end

    def account_name
      json["account"]["username"]
    end

    def image_url
      image_urls.first
    end

    def image_urls
      json["media_attachments"].map {|x| x["url"]}
    end

    def tags
      json["tags"].map { |tag| [tag["name"], tag["url"]] }
    end

    def commentary
      commentary = ""
      commentary << "<p>#{json["spoiler_text"]}</p>" if json["spoiler_text"].present?
      commentary << json["content"]
      commentary
    end
  end

  def get(url)
    if id = Status.is_match?(url)
      Status.new(JSON.parse(access_token.get("/api/v1/statuses/#{id}").body))
    elsif id = Account.is_match?(url)
      Account.new(JSON.parse(access_token.get("/api/v1/accounts/#{id}").body))
    else
      nil
    end
  end

  private

  def fetch_access_token
    raise MissingConfigurationError.new("missing pawoo client id") if Danbooru.config.pawoo_client_id.nil?
    raise MissingConfigurationError.new("missing pawoo client secret") if Danbooru.config.pawoo_client_secret.nil?

    Cache.get("pawoo-token") do
      result = client.client_credentials.get_token
      result.token
    end
  end

  def access_token
    OAuth2::AccessToken.new(client, fetch_access_token)
  end

  def client
    OAuth2::Client.new(Danbooru.config.pawoo_client_id, Danbooru.config.pawoo_client_secret, :site => "https://pawoo.net")
  end

  memoize :client
end
