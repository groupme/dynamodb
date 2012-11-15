require 'typhoeus'
require 'time'
require 'base64'
require 'openssl'
require 'cgi'
require 'multi_json'

module DynamoDB
  class BaseError < RuntimeError
    attr_reader :response

    def initialize(response)
      @response = response
      super("#{response.code}: #{response.body}")
    end
  end

  class ClientError < BaseError; end
  class ServerError < BaseError; end
  class TimeoutError < BaseError; end
  class AuthenticationError < BaseError; end

  require 'dynamodb/typhoeus/request'
  require 'dynamodb/credentials'
  require 'dynamodb/security_token_service'
  require 'dynamodb/connection'
  require 'dynamodb/response'

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
      else
        raise "Type not recoginized: #{k}"
      end
    end
  end
end
