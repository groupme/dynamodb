module DynamoDB
  class Request
    RFC1123 = "%a, %d %b %Y %H:%M:%S GMT"
    ISO8601 = "%Y%m%dT%H%M%SZ"

    attr_reader :uri, :operation, :body, :signer

    def initialize(args = {})
      @uri        = args[:uri]
      @operation  = args[:operation]
      @body       = MultiJson.dump(args[:body])
      @signer     = args[:signer]
    end

    def headers
      @headers ||= signed_headers
    end

    private

    def signed_headers
      date = Time.now.utc
      h = {
        "Date"                 => date.strftime(RFC1123),
        "User-Agent"           => "groupme/dynamodb",
        "Host"                 => uri.host,
        "Content-Type"         => "application/x-amz-json-1.0",
        "Content-Length"       => body.size.to_s,
        "X-AMZ-Date"           => date.strftime(ISO8601),
        "X-AMZ-Target"         => operation,
        "X-AMZ-Content-SHA256" => hexdigest(body || '')
      }
      signer.sign("POST", uri, h, body)
    end

    def hexdigest(value)
      digest = Digest::SHA256.new
      digest.update(value)
      digest.hexdigest
    end
  end
end
