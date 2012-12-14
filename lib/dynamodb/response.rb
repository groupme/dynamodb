module DynamoDB
  class Response
    attr_reader :http_response

    def initialize(http_response)
      @http_response = http_response
    end

    def hash_key_element
      DynamoDB.deserialize(json["LastEvaluatedKey"]["HashKeyElement"])
    end

    def range_key_element
      DynamoDB.deserialize(json["LastEvaluatedKey"]["RangeKeyElement"])
    end

    def item
      return unless json["Item"]
      @item ||= DynamoDB.deserialize(json["Item"])
    end

    def items
      return unless json["Items"]
      @items ||= json["Items"].map { |i| DynamoDB.deserialize(i) }
    end

    private

    def json
      @json ||= MultiJson.load(http_response.body)
    end
  end
end
