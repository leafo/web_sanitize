describe "web_sanitize.query.scan", ->
  import replace_html from require "web_sanitize.query.scan_html"

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
      print "doing tag", require("moon").dump t
      t\replace_inner_html "%%#{t\inner_html!}%%"

    print out


  it "replaces empty tag" , ->
    replace_html "<code></code>", (tag_stack) ->

