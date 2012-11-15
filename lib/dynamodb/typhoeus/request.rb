module Typhoeus
  class Request
    def sign(credentials)
      headers.merge!('x-amzn-authorization' => "AWS3 AWSAccessKeyId=#{credentials.access_key_id},Algorithm=HmacSHA256,Signature=#{digest(credentials.secret_access_key)}")
    end

    private

    def digest(secret_key)
      Base64.encode64(
        OpenSSL::HMAC.digest('sha256', secret_key, Digest::SHA256.digest(string_to_sign))
      ).strip
    end

    def string_to_sign
      "POST\n/\n\nhost:#{parsed_uri.host}\n#{amz_to_sts}\n#{body}"
    end

    def amz_to_sts
      get_amz_headers.sort.map {|key, val| [key, val].join(':') + "\n"}.join
    end

    def get_amz_headers
      headers.select {|key, val| key =~ /\Ax-amz-/}
    end
  end
end
