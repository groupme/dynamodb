require 'spec_helper'
require 'benchmark'

describe Jedlik::Connection do
  describe "#post" do
    let(:token_service) do
      stub(:credentials =>
        Jedlik::Credentials.new(
          "access_key_id",
          "secret_access_key",
          "session_token")
      )
    end

    before do
      Time.stub(:now => Time.at(1332635893)) # Sat Mar 24 20:38:13 -0400 2012

      @url = "https://dynamodb.us-east-1.amazonaws.com/"
      @headers = {
        'Content-Type'          => 'application/x-amz-json-1.0',
        'Host'                  => 'dynamodb.us-east-1.amazonaws.com',
        'X-Amz-Date'            => 'Sun, 25 Mar 2012 00:38:13 GMT',
        'X-Amz-Security-Token'  => 'session_token',
        'X-Amzn-Authorization'  => 'AWS3 AWSAccessKeyId=access_key_id,Algorithm=HmacSHA256,Signature=2xa6v0WW+980q8Hgt+ym3/7C0D1DlkueGMugi1NWE+o='
      }
    end

    describe "#initialize" do
      it "can be initialized with a token service" do
        Jedlik::Connection.new(:token_service => token_service)
      end

      it "can be initialized with an access key" do
        Jedlik::Connection.new(
          :access_key_id => "id",
          :secret_access_key => "secret"
        )
      end

      context "no token service was provided" do
        it "requires an access_key_id and secret_access_key" do
          lambda {
            Jedlik::Connection.new
          }.should raise_error(ArgumentError)
        end
      end
    end

    it "signs and posts a request" do
      @headers['X-Amz-Target'] = 'DynamoDB_20111205.ListTables'
      stub_request(:post, @url).
        with(
          :body     => "{}",
          :headers  => @headers
        ).
        to_return(
          :status => 200,
          :body => '{"TableNames":["example"]}',
          :headers => {}
        )

      connection = Jedlik::Connection.new(:token_service => token_service)
      result = connection.post :ListTables
      result.should == {"TableNames" => ["example"]}
    end

    it "type casts response when Query" do
      stub_request(:post, @url).
        to_return(
          :status => 200,
          :body => "{}",
          :headers => {}
        )

      connection = Jedlik::Connection.new(:token_service => token_service)
      response = connection.post :Query, :TableName => "people", :HashKeyId => {:N => "1"}
      response.should be_a_kind_of(Jedlik::Response)
    end

    it "type casts response when GetItem" do
      stub_request(:post, @url).
        to_return(
          :status => 200,
          :body => "{}",
          :headers => {}
        )

      connection = Jedlik::Connection.new(:token_service => token_service)
      response = connection.post :GetItem, :TableName => "people", :Key => {:HashKeyElement => {:N => "1"}, :RangeKeyElement => {:N => 2}}
      response.should be_a_kind_of(Jedlik::Response)
    end
  end
end
