require "uri"
require 'time'
require 'cgi'
require 'multi_json'

module DynamoDB
  class BaseError < RuntimeError; end
  class ClientError < BaseError; end
  class ServerError < BaseError; end
  class AuthenticationError < BaseError; end

  require 'dynamodb/version'
  require 'dynamodb/connection'
  require 'dynamodb/http_handler'
  require 'dynamodb/request'
  require 'dynamodb/success_response'
  require 'dynamodb/failure_response'

  class << self
    def serialize(object)
      if object.kind_of?(Hash)
        serialized = {}
        object.each do |k, v|
          next if blank?(v)
          serialized[k.to_s] = encode_type(v)
        end
        serialized
      else
        encode_type(object)
      end
    end

    def deserialize(object)
      if object.values.first.kind_of?(Hash)
        deserialized = {}
        object.each do |k, value_hash|
          deserialized[k] = decode_type(value_hash)
        end
        deserialized
      else
        decode_type(object)
      end
    end

    private

    def blank?(object)
      if object.respond_to?(:empty?)
        object.empty?
      else
        object.nil?
      end
    end

    def encode_type(value)
      case value
      when Numeric
        {"N" => value.to_s}
      when TrueClass, FalseClass
        {"N" => (value ? 1 : 0).to_s}
      when Time
        {"N" => value.to_f.to_s}
      when Array
        if value.all? {|n| n.kind_of?(String) }
          {"SS" => value.uniq}
        elsif value.all? {|n| n.kind_of?(Numeric) }
          {"NS" => value.uniq}
        else
          raise ClientError.new("cannot mix data types in sets")
        end
      else
        {"S" => value.to_s}
      end
    end

    def decode_type(value_hash)
      k = value_hash.keys.first
      v = value_hash.values.first
      case k
      when "N" then v.include?('.') ? v.to_f : v.to_i
      when "S" then v.to_s
      when "SS","NS" then v
      else
        raise "Type not recoginized: #{k}"
      end
    end
  end
end
