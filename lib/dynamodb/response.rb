module DynamoDB
  class Response
    attr_reader :typhoeus_response

    def initialize(typhoeus_response)
      @typhoeus_response = typhoeus_response
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
      @json ||= MultiJson.load(typhoeus_response.body)
    end
  end
end
