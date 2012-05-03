require "spec_helper"

describe Jedlik::Credentials do
  describe "#==" do
    it "is true for identical credentials" do
      Jedlik::Credentials.new("abc", "123", "token").should ==
        Jedlik::Credentials.new("abc", "123", "token")
    end

    it "is false otherwise" do
      Jedlik::Credentials.new("abc", "123", "token").should_not ==
        Jedlik::Credentials.new("abc", "123", "different token")
    end
  end

  describe "#to_hash" do
    it "converts to a hash and back" do
      credentials = Jedlik::Credentials.new("abc", "123", "token")
      Jedlik::Credentials.from_hash(credentials.to_hash).should == credentials
    end
  end
end
