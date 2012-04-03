module Jedlik
  class QueryResponse
    include Enumerable
    attr_reader :typhoeus_response

    def initialize(typhoeus_response)
      @typhoeus_response = typhoeus_response
    end

    def hash_key_element
      Jedlik.deserialize(json["LastEvaluatedKey"]["HashKeyElement"])
    end

    def range_key_element
      Jedlik.deserialize(json["LastEvaluatedKey"]["RangeKeyElement"])
    end

    def [](index)
      items[index]
    end

    def each(&block)
      items.each(&block)
    end

    private

    def items
      @items ||= json["Items"].map { |i| Jedlik.deserialize(i) }
    end

    def json
      @json ||= Yajl::Parser.parse(typhoeus_response.body)
    end
  end
end
