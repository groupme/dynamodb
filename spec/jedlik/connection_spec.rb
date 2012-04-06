require 'spec_helper'
require 'benchmark'

describe Jedlik::Connection do
  describe "#post" do
    before do
      Time.stub!(:now).and_return(Time.at(1332635893)) # Sat Mar 24 20:38:13 -0400 2012
      mock_service = mock(Jedlik::SecurityTokenService,
        :session_token => "session_token",
        :access_key_id => "access_key_id",
        :secret_access_key => "secret_access_key"
      )
      Jedlik::SecurityTokenService.stub!(:new).and_return(mock_service)
      @url = "https://dynamodb.us-east-1.amazonaws.com/"
      @headers = {
        'Content-Type'          => 'application/x-amz-json-1.0',
        'Host'                  => 'dynamodb.us-east-1.amazonaws.com',
        'X-Amz-Date'            => 'Sun, 25 Mar 2012 00:38:13 GMT',
        'X-Amz-Security-Token'  => 'session_token',
        'X-Amzn-Authorization'  => 'AWS3 AWSAccessKeyId=access_key_id,Algorithm=HmacSHA256,Signature=2xa6v0WW+980q8Hgt+ym3/7C0D1DlkueGMugi1NWE+o='
      }

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

      connection = Jedlik::Connection.new("key_id", "secret")
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

      connection = Jedlik::Connection.new("key_id", "secret")
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

      connection = Jedlik::Connection.new("key_id", "secret")
      response = connection.post :GetItem, :TableName => "people", :Key => {:HashKeyElement => {:N => "1"}, :RangeKeyElement => {:N => 2}}
      response.should be_a_kind_of(Jedlik::Response)
    end

    context "on authentication failure" do
      it "reauthenticates" do
        @headers['X-Amz-Target'] = 'DynamoDB_20111205.ListTables'
        stub_request(:post, @url).
          with(
            :body     => "{}",
            :headers  => @headers
          ).
          to_return(:status => 403)

        connection = Jedlik::Connection.new("key_id", "secret")
        connection.should_receive(:authenticate)
        connection.post :ListTables
      end
    end
  end

  describe "#authenticate" do
    it "refreshes session credentials" do
      mock_service = mock(Jedlik::SecurityTokenService)
      Jedlik::SecurityTokenService.stub!(:new).and_return(mock_service)
      mock_service.should_receive(:refresh_credentials)

      connection = Jedlik::Connection.new("key_id", "secret")
      connection.authenticate
    end
  end

  describe "#credentials" do
    before do
      mock_service = mock(Jedlik::SecurityTokenService,
        :session_token => "session_token",
        :access_key_id => "access_key_id",
        :secret_access_key => "secret_access_key"
      )
      Jedlik::SecurityTokenService.stub!(:new).and_return(mock_service)
    end

    it "returns the session_token" do
      connection = Jedlik::Connection.new("key_id", "secret")
      connection.credentials.should == {
        :session_token => "session_token",
        :access_key_id => "access_key_id",
        :secret_access_key => "secret_access_key"
      }
    end
  end

  describe "#credentials=" do
    before do
      @mock_service = mock(Jedlik::SecurityTokenService)
      Jedlik::SecurityTokenService.stub!(:new).and_return(@mock_service)
    end

    it "sets credentials on STS" do
      connection = Jedlik::Connection.new("key_id", "secret")
      @mock_service.should_receive(:access_key_id=).with("access_key_id")
      @mock_service.should_receive(:secret_access_key=).with("secret_access_key")
      @mock_service.should_receive(:session_token=).with("session_token")

      connection.credentials = {
        :access_key_id => "access_key_id",
        :secret_access_key => "secret_access_key",
        :session_token => "session_token"
      }
    end

    it "raises an ArgumentError with bad arguments" do
      connection = Jedlik::Connection.new("key_id", "secret")
      proc {
        connection.credentials = {"foo" => "bar"}
      }.should raise_error(ArgumentError)
    end
  end
end
