
flatten_html = (html) ->
  ((html\gsub "%s+%<", "><")\match("^%s*(.-)%s*$"))

describe "web_sanitize.query.scan", ->
  import replace_html, scan_html from require "web_sanitize.query.scan_html"

  describe "scan_html", ->
    it "scans html with unclosed tag", ->
      visited = {}

      scan_html [[
        <div class="hello">
          </p>
        </div>
        </code>
        <span>
        <ul>hello
        </span>
        <pre>
        hello world
      ]], (stack) ->
        table.insert visited, stack\current!.tag

      -- it should also get the pre
      assert.same {"div", "ul", "span", "pre"}, visited

    it "gets content of dangling tags", ->
      visited = {}

      scan_html [[
        <div>one
        <span>two
      ]], (stack) ->
        table.insert visited,
          flatten_html stack\current!\outer_html!

      assert.same {
        "<span>two",
        "<div>one><span>two"
      }, visited

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

    it "replaces attributes", ->
      out = replace_html "<div>1</div> <pre height=59>2</pre> <span>3</span>", (stack) ->
        stack\current!\replace_attributes { color: "blue", x: [["]] }

      one_of = {
        [[<div x="&quot;" color="blue">1</div> <pre x="&quot;" color="blue">2</pre> <span x="&quot;" color="blue">3</span>]]
        [[<div color="blue" x="&quot;">1</div> <pre color="blue" x="&quot;">2</pre> <span color="blue" x="&quot;">3</span>]]
      }

      for thing in *one_of
        if thing == out
          assert.same thing, out
          return

      assert.same one_of[1], out

  describe "NodeStack", ->
    it "adds slugs ids to headers", ->
      slugify = (str) ->
        (str\gsub("[%s_]+", "-")\gsub("[^%w%-]+", "")\gsub("-+", "-"))\lower!

      document = [[
        <section>
          <h1>Eating the right foods is right</h1>
          <p>How do do something right?/</p>
        </section>

        <section>
          <h2>The death of the gold coast</h2>
          <p>Good day fart</p>
        </section>
      ]]

      out = replace_html document, (stack) ->
        return unless stack\is "h1, h2"
        el = stack\current!
        el\replace_attributes {
          id: slugify el\inner_text!
        }

      assert.same [[
        <section>
          <h1 id="eating-the-right-foods-is-right">Eating the right foods is right</h1>
          <p>How do do something right?/</p>
        </section>

        <section>
          <h2 id="the-death-of-the-gold-coast">The death of the gold coast</h2>
          <p>Good day fart</p>
        </section>
      ]], out

    it "uses is and select", ->
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
