require 'spec_helper'

describe Jedlik do
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

      Jedlik.serialize(hash).should == {
        "id" => {"N" => "1"},
        "name" => {"S" => "Gone with the Wind"},
        "published_at" => {"N" => published_at.to_f.to_s},
        "price" => {"N" => "11.99"},
        "active" => {"N" => "1"}
      }
    end
  end

  describe "#deserialize" do
    it "deserializes single values" do
      Jedlik.deserialize({"N" => "123"}).should == 123
      Jedlik.deserialize({"S" => "Hello World"}).should == "Hello World"
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
      deserialized = Jedlik.deserialize(item)
      deserialized["id"].should == 1
      deserialized["name"].should == "Gone with the Wind"
      deserialized["published_at"].to_s.should == published_at.to_f.to_s
      deserialized["price"].should == 11.99
      deserialized["active"].should == 1
    end
  end
end
