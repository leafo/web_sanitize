

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

      {
        html: "<div>hello</div>"
        query: "div"
        outer_html: {"<div>hello</div>"}
        inner_html: {"hello"}
      }

      {
        html: "a  <div>he<div>ll</div>o</div> b"
        query: "div"
        outer_html: {"<div>he<div>ll</div>o</div>", "<div>ll</div>"}
        inner_html: {"he<div>ll</div>o", "ll"}
      }

      {
        html: "a  <div><span class='yeah'>ok</span></div> b"
        query: ".yeah"
        outer_html: {"<span class='yeah'>ok</span>"}
        inner_html: {"ok"}
      }

      {
        html: "a  <div><span class='yeah'>ok</span></div> b"
        query: "div .yeah"
        outer_html: {"<span class='yeah'>ok</span>"}
        inner_html: {"ok"}
      }

      {
        -- matches when there is an element inbetween
        html: "a  <div class='ok'><pre><span class='yeah'>ok</span></pre></div> b"
        query: ".ok .yeah"
        outer_html: {"<span class='yeah'>ok</span>"}
        inner_html: {"ok"}
      }

      {
        -- fails with adjacent
        html: "a  <div class='ok'></div><span class='yeah'>ok</span> b"
        query: ".ok .yeah"
        outer_html: {}
        inner_html: {}
      }

    }

    for {:html, :query,  :outer_html, :inner_html} in *tests
      it "matches", ->
        res = query_all html, query

        got = [r\outer_html! for r in *res]
        table.sort got
        table.sort outer_html
        assert.same outer_html, got

        got = [r\inner_html! for r in *res]
        table.sort got
        table.sort inner_html
        assert.same inner_html, got

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


