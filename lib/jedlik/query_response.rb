module Jedlik
  class QueryResponse
    include Enumerable
    attr_reader :typhoeus_response

    def initialize(typhoeus_response)
      @typhoeus_response = typhoeus_response
    end

    def hash_key_element
      convert_value(json["LastEvaluatedKey"]["HashKeyElement"])
    end

    def range_key_element
      convert_value(json["LastEvaluatedKey"]["RangeKeyElement"])
    end

    def [](index)
      items[index]
    end

    def each(&block)
      items.each(&block)
    end

    private

    def items
      @items ||= json["Items"].map { |i| convert_hash(i) }
    end

    def json
      @json ||= Yajl::Parser.parse(typhoeus_response.body)
    end

    def convert_value(value_hash)
      typecast(value_hash.keys.first, value_hash.values.first)
    end

    def convert_hash(hash)
      result = {}
      hash.each do |key, value_hash|
        result[key] = convert_value(value_hash)
      end
      result
    end

    def typecast(k, v)
      case k
      when "N" then v.include?('.') ? v.to_f : v.to_i
      when "S" then v.to_s
      else
        raise "Type not recoginized: #{k}"
      end
    end
  end
end
