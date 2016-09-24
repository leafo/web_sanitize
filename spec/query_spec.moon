
unpack = unpack or table.unpack

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

      {
        -- *
        html: "a  <div class='ok'></div><span class='yeah'>ok</span> b"
        query: "*"
        outer_html: {"<div class='ok'></div>", "<span class='yeah'>ok</span>"}
        inner_html: {"", "ok"}
      }


      {
        -- matches when there is an element inbetween
        html: [[<div class="hello"></div><div class="hello world"><pre></pre></div>
          <div class="world"></div><div class="helloworld"></div>]]
        query: ".hello.world"
        outer_html: {[[<div class="hello world"><pre></pre></div>]]}
        inner_html: {"<pre></pre>"}
      }


      {
        html: [[<div class="hello">first</div><div class="hello">second</div>]]
        query: ".hello:nth-child(2)"
        outer_html: {'<div class="hello">second</div>'}
        inner_html: {"second"}
      }

      {
        -- handles tag mismatch when there should be match, matches inner
        html: [[<pre class="hello"><div class="ok">hello world</pre>]]
        query: ".ok"
        outer_html: {[[<div class="ok">hello world]]}
        inner_html: {[[hello world]]}
      }

      {
        -- handles tag mismatch when there should be match, matches outer
        html: [[<code><pre class="hello"><div class="ok">hello world</pre></code>]]
        query: ".hello"
        outer_html: {[[<pre class="hello"><div class="ok">hello world</pre>]]}
        inner_html: {[[<div class="ok">hello world]]}
      }

      {
        -- handles tag mismatch when there is unknown closing tag
        html: [[<code><div class="ok">hello world</pre></code>]]
        query: ".ok"
        outer_html: {[[<div class="ok">hello world</pre>]]}
        inner_html: {[[hello world</pre>]]}
      }

      {
        -- valueless attribute
        html: [[<script async src="http://leafo.net/hi.js"></script>]]
        query: "script"
        outer_html: {[[<script async src="http://leafo.net/hi.js"></script>]]}
        inner_html: {[[]]}
      }


      {
        -- ignore fail tag
        html: [[<leafot hello="world"<div@leafo.net><div class="fun"></div>]]
        query: ".fun"
        outer_html: {[[<div class="fun"></div>]]}
        inner_html: {[[]]}
      }

      {
        html: [[one <a href="y">a</a> o <a href="x" data-cool="one">b</a> two<div data-cool></div>]]
        query: "[data-cool]"
        outer_html: {
          [[<a href="x" data-cool="one">b</a>]]
          [[<div data-cool></div>]]
        }
        inner_html: {"b", ""}
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

    it "queries for void tag", ->
      res = query_all [[
        <div class="butt">
          <img data-dad="yeah" src="http://leafo.net/hi.png" />
        </div>
      ]], ".butt img"

      assert.same 1, #res
      res = unpack res
      assert.same [[<img data-dad="yeah" src="http://leafo.net/hi.png" />]],
        res\outer_html!

    it "queries for unclosed void tag", ->
      res = query_all [[
        <meta data-cool="stuff">
        <div class="butt">hello world</div>
      ]], "meta"

      assert.same 1, #res
      res = unpack res
      assert.same [[<meta data-cool="stuff">]],
        res\outer_html!

  describe "parse_query", ->
    import parse_query from require "web_sanitize.query.parse_query"

    it "parses tags", ->
      assert.same {
        {
          { {"tag", "hello"} }
          { {"tag", "world"} }
        }
      }, parse_query "hello world"

    it "parses classes", ->
      assert.same {
        {
          { {"class", "hello"} }
          { {"class", "world"} }
        }
      }, parse_query ".hello .world"

    it "parses ids", ->
      assert.same {
        {
          { {"id", "hello"} }
          { {"id", "world"} }
        }
      }, parse_query "#hello #world"

    it "parses combo", ->
      assert.same {
        {
          {{"tag", "div"}, {"class", "yea"}}
          {{"id", "what"}}
          {{"class", "colorful"}}
        }
      }, parse_query "div.yea #what .colorful"

    it "parses alternatives", ->
      assert.same {
        {
          {{"tag", "pre"}}
        }
        {
          {{"tag", "code"}}
        }
      }, parse_query "pre, code"

    it "parses complex alternatives", ->
      assert.same {
        {
          {{"any", "*"}, {"nth-child", "2"}}
          {{"class", "cool"}}
        }
        {
          {{"tag", "span"}}
          {{"tag", "div"}, {"id", "okay"}}
        }
      }, parse_query "*:nth-child(2) .cool, span div#okay"

    it "parses attribute existance", ->
      assert.same {
        {
          {{"class", "hello"}, {"attr", "world"}}
        }
      }, parse_query ".hello[world]"

    it "failes when part of query doesn't match", ->
      -- TODO: give error messagess and error locations
      assert.nil parse_query "div.hellok, 838r290@#$$##"


