module DynamoDB
  # Successful response from Dynamo
  class SuccessResponse
    attr_reader :http_response

    def initialize(http_response)
      @http_response = http_response
    end

    def hash_key_element
      DynamoDB.deserialize(data["LastEvaluatedKey"]["HashKeyElement"])
    end

    def range_key_element
      DynamoDB.deserialize(data["LastEvaluatedKey"]["RangeKeyElement"])
    end

    # Return single item response as a Hash
    #
    # Some DynamoDB operations, such as `GetItem`, will only return a
    # single 'Item' entry. This converts that entry in a Hash where
    # values have been type-casted into their Ruby equivalents.
    def item
      return unless data["Item"]
      @item ||= DynamoDB.deserialize(data["Item"])
    end

    # Return an Array of item responses
    #
    # DynamoDB operations like `Query` return a collection of entries
    # under the 'Items' key. This returns an Array of Hashes where
    # values have been casted to their Ruby equivalents.
    def items
      return unless data["Items"]
      @items ||= data["Items"].map { |i| DynamoDB.deserialize(i) }
    end

    def responses
      return unless data["Responses"]
      @responses ||= build_responses
    end
    def success?
      true
    end

    def body
      http_response.body
    end

    # Access the deserialized JSON response body
    def data
      @data ||= MultiJson.load(http_response.body)
    end

    private

    def build_responses
      responses = {}
      data["Responses"].keys.each do |key|
        items = data["Responses"][key].map { |i| DynamoDB.deserialize(i)}
        responses[key] = items
      end
      responses
    end
  end
end
