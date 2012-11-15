require 'spec_helper'

describe DynamoDB do
  describe "#serialize" do
    it "serializes to dynamo type format" do
      published_at = Time.now
      hash = {
        :id => 1,
        :name => "Gone with the Wind",
        :published_at => published_at,
        :price => 11.99,
        :active => true
      }

      DynamoDB.serialize(hash).should == {
        "id" => {"N" => "1"},
        "name" => {"S" => "Gone with the Wind"},
        "published_at" => {"N" => published_at.to_f.to_s},
        "price" => {"N" => "11.99"},
        "active" => {"N" => "1"}
      }
    end

    it "serializes a single value" do
      DynamoDB.serialize(1).should == {"N" => "1"}
      DynamoDB.serialize(1.5).should == {"N" => "1.5"}
      DynamoDB.serialize("Hello World").should == {"S" => "Hello World"}
    end

    it "omits nil/blank values" do
      DynamoDB.serialize("foo" => nil).should == {}
      DynamoDB.serialize("foo" => "").should == {}
    end
  end

  describe "#deserialize" do
    it "deserializes single values" do
      DynamoDB.deserialize({"N" => "123"}).should == 123
      DynamoDB.deserialize({"S" => "Hello World"}).should == "Hello World"
    end

    it "deserializes from dynamo type format" do
      published_at = Time.now
      item = {
        "id" => {"N" => "1"},
        "name" => {"S" => "Gone with the Wind"},
        "published_at" => {"N" => published_at.to_f.to_s},
        "price" => {"N" => "11.99"},
        "active" => {"N" => "1"}
      }
      deserialized = DynamoDB.deserialize(item)
      deserialized["id"].should == 1
      deserialized["name"].should == "Gone with the Wind"
      deserialized["published_at"].to_s.should == published_at.to_f.to_s
      deserialized["price"].should == 11.99
      deserialized["active"].should == 1
    end
  end
end
