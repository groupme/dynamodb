module Jedlik

  # Establishes a connection to Amazon DynamoDB using credentials.
  class Connection
    attr_reader :sts

    DEFAULTS = {
      :endpoint => 'dynamodb.us-east-1.amazonaws.com',
    }

    # Acceptable `opts` keys are:
    #
    #     :endpoint # DynamoDB endpoint to use.
    #               # Default: 'dynamodb.us-east-1.amazonaws.com'
    #
    def initialize(access_key_id, secret_access_key, opts={})
      opts = DEFAULTS.merge opts
      @sts = SecurityTokenService.new(access_key_id, secret_access_key)
      @endpoint = opts[:endpoint]
    end

    # Create and send a request to DynamoDB.
    # Returns a hash extracted from the response body.
    #
    # `operation` can be any DynamoDB operation. `data` is a hash that will be
    # used as the request body (in JSON format). More info available at:
    #
    # http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide
    #
    def post(operation, data={})
      request = new_request(operation, data.to_json)
      request.sign(sts)
      hydra.queue(request)
      hydra.run
      response = request.response

      if status_ok?(response)
        JSON.parse(response.body)
      end
    end

    private

    def hydra
      Typhoeus::Hydra.hydra
    end

    def new_request(operation, body)
      Typhoeus::Request.new "https://#{@endpoint}/",
        :method   => :post,
        :body     => body,
        :headers  => {
          'host'                  => @endpoint,
          'content-type'          => "application/x-amz-json-1.0",
          'x-amz-date'            => (Time.now.utc.strftime "%a, %d %b %Y %H:%M:%S GMT"),
          'x-amz-security-token'  => sts.session_token,
          'x-amz-target'          => "DynamoDB_20111205.#{operation}",
        }
    end

    def status_ok?(response)
      case response.code
      when 200
        true
      when 400..499
        js = JSON.parse(response.body)
        raise ClientError, "#{js['__type'].match(/#(.+)\Z/)[1]}: #{js["message"]}"
      when 500..599
        raise ServerError
      else
        false
      end
    end
  end
end
