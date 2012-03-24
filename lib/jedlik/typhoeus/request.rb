module Typhoeus
  class Request
    def sign(sts)
      auth = {
        'x-amzn-authorization' => [
          "AWS3 AWSAccessKeyId=#{sts.access_key_id}",
          "Algorithm=HmacSHA256",
          "Signature=#{digest sts.secret_access_key}"
        ].join(',')
      }
      headers.merge!(auth)
    end

    private

    def digest(secret_key)
      digested = OpenSSL::HMAC.digest(
        'sha256',
        secret_key,
        Digest::SHA256.digest(string_to_sign)
      )
      Base64.encode64(digested).chomp
    end

    def string_to_sign
      ["POST\n/\n\nhost:#{@parsed_uri.host}", amz_to_sts, body].join("\n")
    end

    def amz_to_sts
      get_amz_headers.sort.map {|key, val| [key, val].join(':') + "\n"}.join
    end

    def get_amz_headers
      headers.select {|key, val| key =~ /\Ax-amz-/}
    end
  end
end
