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

      expect(DynamoDB.serialize(hash)).to eq({
        "id" => {"N" => "1"},
        "name" => {"S" => "Gone with the Wind"},
        "published_at" => {"N" => published_at.to_f.to_s},
        "price" => {"N" => "11.99"},
        "active" => {"N" => "1"}
      })
    end

    it "serializes a single value" do
      expect(DynamoDB.serialize(1)).to eq({"N" => "1"})
      expect(DynamoDB.serialize(1.5)).to eq({"N" => "1.5"})
      expect(DynamoDB.serialize("Hello World")).to eq({"S" => "Hello World"})
    end

    it "omits nil/blank values" do
      expect(DynamoDB.serialize("foo" => nil)).to eq({})
      expect(DynamoDB.serialize("foo" => "")).to eq({})
    end

    it "serializes StringSet" do
      expect(DynamoDB.serialize(["foo", "bar", "foo"])).to eq({"SS" => ["foo", "bar"]})
    end

    it "serializes NumberSet" do
      expect(DynamoDB.serialize([1, 2, 1])).to eq({"NS" => [1,2]})
    end

    it "raises an error on mixed types" do
      expect {
        DynamoDB.serialize([1, "2", 1])
      }.to raise_error
    end
  end

  describe "#deserialize" do
    it "deserializes single values" do
      expect(DynamoDB.deserialize({"N" => "123"})).to eq(123)
      expect(DynamoDB.deserialize({"S" => "Hello World"})).to eq("Hello World")
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
      expect(deserialized["id"]).to eq(1)
      expect(deserialized["name"]).to eq("Gone with the Wind")
      expect(deserialized["published_at"].to_s).to eq(published_at.to_f.to_s)
      expect(deserialized["price"]).to eq(11.99)
      expect(deserialized["active"]).to eq(1)
    end

    it "deserializes StringSet and NumberSet" do
      item = {
        "turtles" => {"SS" => ["Leonardo", "Michelangelo"]},
        "powerball" => {"NS" => [1,2]}
      }
      deserialized = DynamoDB.deserialize(item)
      expect(deserialized["turtles"]).to eq(["Leonardo", "Michelangelo"])
      expect(deserialized["powerball"]).to eq([1,2])
    end

    it "deserializes NULL" do
      item = {
        "turtles" => {"NULL" => true}
      }
      deserialized = DynamoDB.deserialize(item)
      expect(deserialized["turtles"]).to be_nil
    end
  end
end
