describe "web_sanitize.query.scan", ->
  it "replaces tag content", ->
    import replace_html from require "web_sanitize.query.scan_html"
    out = replace_html "<div>hello world</div>", (tag_stack) ->
      t = tag_stack[#tag_stack]
      t\replace_inner_html "%#{t\inner_html!}%"

    assert.same "<div>%hello world%</div>", out
