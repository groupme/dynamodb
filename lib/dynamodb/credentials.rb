module DynamoDB
  class Credentials
    attr_reader :access_key_id, :secret_access_key, :session_token

    def self.from_hash(hash)
      new(hash["access_key_id"], hash["secret_access_key"], hash["session_token"])
    end

    def initialize(access_key_id, secret_access_key, session_token)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @session_token = session_token
    end

    def to_hash
      {
        "access_key_id" => access_key_id,
        "secret_access_key" => secret_access_key,
        "session_token" => session_token
      }
    end

    def ==(other)
      self.class == other.class &&
      access_key_id == other.access_key_id &&
      secret_access_key == other.secret_access_key &&
      session_token == other.session_token
    end
  end
end
