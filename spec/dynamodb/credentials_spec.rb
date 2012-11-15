require "spec_helper"

describe DynamoDB::Credentials do
  describe "#==" do
    it "is true for identical credentials" do
      DynamoDB::Credentials.new("abc", "123", "token").should ==
        DynamoDB::Credentials.new("abc", "123", "token")
    end

    it "is false otherwise" do
      DynamoDB::Credentials.new("abc", "123", "token").should_not ==
        DynamoDB::Credentials.new("abc", "123", "different token")
    end
  end

  describe "#to_hash" do
    it "converts to a hash and back" do
      credentials = DynamoDB::Credentials.new("abc", "123", "token")
      DynamoDB::Credentials.from_hash(credentials.to_hash).should == credentials
    end
  end
end
