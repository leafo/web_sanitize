

describe "query", ->
  describe "query_all", ->
    import query_all from require "web_sanitize.query"

    tests = {
      {
        html: ""
        query: "div"
        outer_html: {}
        inner_html: {}
      }
    }

    for {:html, :query,  :outer_html, :inner_html} in *tests
      it "matches", ->
        res = query_all html, query
        assert.same outer_html, [r\outer_html! for r in *res]
        assert.same inner_html, [r\inner_html! for r in *res]

  describe "parse_query", ->
    import parse_query from require "web_sanitize.query.parse_query"

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

    it "parses combo", ->
      assert.same {
        {{"tag", "div"}, {"class", "yea"}}
        {{"id", "what"}}
        {{"class", "colorful"}}
      }, parse_query "div.yea #what .colorful"


