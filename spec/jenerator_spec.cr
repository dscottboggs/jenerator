require "./spec_helper"

describe Jenerator do
  describe "an array of objects" do
    it "eliminates redundant types from the member type but doesn't prevent them from being output" do
      text = <<-JSON
        {
          "data": [
            {"x": 1, "y": 2}, {"x": 3, "y": 4}, {"x": 5, "a": 6}, "some text, why not?"
          ]
        }
      JSON
      code = Jenerator.process text
      code.should eq <<-CRYSTAL
      require "json"

      class Document
        include JSON::Serializable

        class DataArrayMember1
          include JSON::Serializable
          @x : Int64
          @y : Int64
        end

        class DataArrayMember2
          include JSON::Serializable
          @x : Int64
          @y : Int64
        end

        class DataArrayMember3
          include JSON::Serializable
          @x : Int64
          @a : Int64
        end

        @data : Array(DataArrayMember1 | DataArrayMember3 | String)
      end\n
      CRYSTAL
      # Note DataArrayMember2 is still declared, even though it's never used.
    end
  end
end
