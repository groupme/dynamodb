require 'typhoeus'
require 'time'
require 'base64'
require 'openssl'
require 'cgi'
require 'yajl'

module Jedlik
  class ClientError < Exception; end
  class ServerError < Exception; end

  require 'jedlik/typhoeus/request'
  require 'jedlik/security_token_service'
  require 'jedlik/connection'
end
