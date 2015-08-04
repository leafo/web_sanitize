
import parse_query from require "web_sanitize.query.parse_query"

describe "query", ->
  describe "parse_query", ->
    it "parses tags", ->
      assert.same {
        { {"tag", "hello"} }
        { {"tag", "world"} }
      }, parse_query "hello world"

    it "parses classes", ->
      assert.same {
        { {"class", "hello"} }
        { {"class", "world"} }
      }, parse_query ".hello .world"

    it "parses ids", ->
      assert.same {
        { {"id", "hello"} }
        { {"id", "world"} }
      }, parse_query "#hello #world"


