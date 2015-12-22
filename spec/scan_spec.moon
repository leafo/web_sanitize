describe "web_sanitize.query.scan", ->
  import replace_html, scan_html from require "web_sanitize.query.scan_html"

  describe "replace_html", ->
    it "replaces tag content", ->
      out = replace_html "<div>hello world</div>", (tag_stack) ->
        t = tag_stack[#tag_stack]
        t\replace_inner_html "%#{t\inner_html!}%"

      assert.same "<div>%hello world%</div>", out

    it "replaces tag content with overlaps, destructive", ->
      -- makes it longer
      out = replace_html "<div>hello <span>zone</span>world</div>", (tag_stack) ->
        t = tag_stack[#tag_stack]
        t\replace_inner_html "%%#{t\inner_html!}%%"

      assert.same "<div>%%hello <span>zone</span>world%%</div>", out

      -- makes it shorter
      out = replace_html "<div>hello <span>zone</span>world</div>", (tag_stack) ->
        t = tag_stack[#tag_stack]
        t\replace_inner_html "X"

      assert.same "<div>X</div>", out

    it "replaces consecutive tags #ddd" , ->
      out = replace_html "<div>1</div> <pre>2</pre> <span>3</span>", (tag_stack) ->
        t = tag_stack[#tag_stack]
        t\replace_inner_html "%%#{t\inner_html!}%%"

      assert.same "<div>%%1%%</div> <pre>%%2%%</pre> <span>%%3%%</span>", out

    it "replaces empty tag" , ->
      out = replace_html "<code></code>", (tag_stack) ->
        t = tag_stack[#tag_stack]
        t\replace_inner_html "%%hi%%"

      assert.same "<code>%%hi%%</code>", out

  describe "NodeStack", ->
    html = [[
      <div class="hello">
        <code>
          The line:
          <div>
            the <span class="cool">Here!</span>
          </div>
          end
        </code>
      </div>
    ]]

    hits = 0
    misses = 0

    scan_html html, (stack) ->
      if stack\is "span"
        hits += 1
        divs = stack\select "div"
        assert.same 2, #divs
      else
        misses += 1

    assert.same 1, hits
    assert.same 3, misses
