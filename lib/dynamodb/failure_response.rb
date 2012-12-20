module DynamoDB
  # Failed response from Dynamo
  #
  # The #error can be:
  # * `ClientError` for 4XX responses
  # * `ServerError` for 5XX or unknown responses
  # * Network errors, which are enumerated in HttpHandler
  class FailureResponse
    attr_accessor :error

    def initialize(http_response = nil)
      @http_response = http_response
    end

    def success?
      false
    end

    def error
      @error ||= http_response_error
    end

    private

    def http_response_error
      if (400..499).include?(@http_response.code.to_i)
        ClientError.new("#{@http_response.code}: #{@http_response.message}")
      else
        ServerError.new("#{@http_response.code}: #{@http_response.message}")
      end
    end
  end
end
