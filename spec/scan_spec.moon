
unpack = unpack or table.unpack

trim = (str) ->
  (str\gsub("^%s+", "")\reverse()\gsub("^%s+", "")\reverse!)

flatten_html = (html) ->
  trim (html\gsub "%s+%<", "<")

describe "web_sanitize.patterns", ->
  describe "open_tag", ->
    -- NOTE: open tag integration testing mostly done in the scan_html specs
    -- below, but feel free to add more unit tests here
    for tuple in *{
      {"hello", nil}
      {">div<", nil}
      {"<div /", nil}
      {"<div thing='what' /", nil}
      {[[<div thing="what>]], nil}
      {"< DIV >", {
        tag: "DIV"
        pos: 1
        inner_pos: 8
      }}

      {"< img aria-hidden Colour = blu/ >", {
        tag: "img"
        pos: 1
        inner_pos: 34
        self_closing: true
        attr: {
          {"aria-hidden"}
          {"Colour", "blu"}
        }
      }}
    }
      it "matches #{tuple[1]}", ->
        import open_tag from require "web_sanitize.patterns"
        assert.same {
          select 2, unpack tuple
        }, { open_tag\match tuple[1] }


  describe "html comment", ->
    for tuple in *{
      {"hello", nil}
      {"<! what", nil}
      {"<!- -what-->", nil}
      {"<!-->-->", nil}
      {"<!--->-->", nil}
      {"<!-- <!--  -->", nil}
      {"<!--f<!--->", nil}
      {"<!->", nil}
      {"<!-->", nil}
      {"<!--->", nil}
      {"<!---->", 8}
      {"<!-- -->", 9}

      {"<!-- -->-->", 9}

      {"<!--f>-->", 10}
      {"<!--f->-->", 11}

      {"<!-- hello world -->", 21}
      {"<!--hello world-->", 19}

      {"<!--My favorite operators are > and <!-->", 42}
    }
      it "matches #{tuple[1]}", ->
        import html_comment from require "web_sanitize.patterns"
        assert.same {
          select 2, unpack tuple
        }, { html_comment\match tuple[1] }


  describe "cdata", ->
    for tuple in *{
      {"hello", nil}
      {"<![CDATA[<![CDATA[]]>", 22}
      {"<![CDATA[]]>", 13}
      {"<![CDATA[<div>hello world</div>]]>", 35}
    }
      it "matches #{tuple[1]}", ->
        import cdata from require "web_sanitize.patterns"
        assert.same {
          select 2, unpack tuple
        }, { cdata\match tuple[1] }



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

    it "automatically closes nested tags", ->
      result = {}

      scan_html "<a><b><c><d>Hello</a></a>", (stack) ->
        node = stack\current!
        table.insert result, node\outer_html!

      assert.same {
        "<d>Hello"
        "<c><d>Hello"
        "<b><c><d>Hello"
        "<a><b><c><d>Hello</a>"
      }, result

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
        "<div>one<span>two"
      }, visited

    it "skips over doctype tag", ->
      nodes = {}

      scan_html [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">]], (stack) ->
          table.insert nodes, stack\current!

      assert.same {}, nodes

    it "scans past html comment", ->
      nodes = {}
      scan_html [[TEst<!-- hello world --><div></div>]], (stack) ->
        table.insert nodes, stack\current!

      assert.same {
        {
          end_inner_pos: 30
          end_pos: 36
          pos: 25
          num: 1
          tag: "div"
          inner_pos: 30
        }
      }, nodes

    it "ignores markup in comment", ->
      nodes = {}
      scan_html [[<!-- <div></div> -->]], (stack) ->
        table.insert nodes, stack\current!

      assert.same { }, nodes

    it "doesn't capture close tag inside comment", ->
      text = {}
      scan_html [[<div>Hello <!-- </div> --> world]], (stack) ->
        table.insert text, stack\current!\inner_html!

      assert.same { "Hello <!-- </div> --> world" }, text

    it "ignores markup in data", ->
      nodes = {}
      scan_html "<![CDATA[<div></div>]]>", (stack) ->
        table.insert nodes, stack\current!

      assert.same { }, nodes

    it "scans common html tag", ->
      nodes = {}
      scan_html [[
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"></html>
        <  DIV />
        <table cellpadding=5>
      ]], (stack) ->
        table.insert nodes, stack\current!

      assert.same {
        {
          tag: "html"
          end_inner_pos: 76
          end_pos: 83
          inner_pos: 76
          num: 1
          pos: 9
          attr: {
            { "xmlns", "http://www.w3.org/1999/xhtml"}
            { "xml:lang", "en"}
            { "lang", "en"}

            xmlns: "http://www.w3.org/1999/xhtml"
            "xml:lang": "en"
            lang: "en"
          }
        }

        {
          tag: "div"
          num: 2
          end_inner_pos: 101
          end_pos: 101
          inner_pos: 101
          num: 2
          pos: 92
          self_closing: true
        }

        {
          tag: "table"
          attr: {
            {"cellpadding", "5"}

            cellpadding: '5'
          }
          end_inner_pos: 138
          end_pos: 138
          inner_pos: 131
          num: 3
          pos: 110
        }

      }, nodes

    it "scans attributes", ->
      expected = {
        div: {
          {"data-dad", '"&'}
          {"CLASS", "blue"}
          {"style", "height: 20px"}
          {"readonly"}


          "data-dad": '"&'
          class: "blue"
          style: "height: 20px"
          readonly: true
        }
        hr: {
          {"ID", "divider"}
          {"allowFullscreen"}

          id: "divider"
          allowfullscreen: true
        }
        img: {
          {"src", ""}
          {"alt", ""}
          {"aria-hidden", "true"}

          src: ""
          alt: ""
          "aria-hidden": "true"
        }
      }

      scan_html [[
        <div data-dad="&quot;&amp;" CLASS="blue" style="height: 20px" readonly>
          <hr ID="divider" allowFullscreen />
          <img src="" alt="" aria-hidden=true>
        </div>
      ]], (stack) ->
        node = stack\current!
        assert.same expected[node.tag], node.attr


    it "scans through rawtext script", ->
      nodes = {}
      scan_html [[
        <script type="text/javascript">
          <hr ID="divider" allowFullscreen />
          &Aacute
          <img src="" alt="" aria-hidden=true>
          <div>
        </script>
      ]], (stack) ->
        node = stack\current!
        table.insert nodes, node

      assert.same {
        {
          attr: {
            {"type", "text/javascript"}
            type: "text/javascript"
          }
          end_inner_pos: 176
          end_pos: 185
          inner_pos: 40
          num: 1
          pos: 9
          tag: 'script'
        }
      }, nodes

      assert.same trim([[
          <hr ID="divider" allowFullscreen />
          &Aacute
          <img src="" alt="" aria-hidden=true>
          <div>
        ]]), trim(nodes[1]\inner_html!)
      assert.same [[Á]], nodes[1]\inner_text!


    it "scans rawtext that has no end", ->
      nodes = {}
      scan_html [[
        <script type="text/javascript">
          <hr ID="divider" allowFullscreen />
          &Aacute
          <img src="" alt="" aria-hidden=true>
          </div>
      ]], (stack) ->
        node = stack\current!
        table.insert nodes, node

      assert.same {
        {
          attr: {
            {"type", "text/javascript"}
            type: "text/javascript"
          }
          end_inner_pos: 175
          end_pos: 175
          inner_pos: 40
          num: 1
          pos: 9
          tag: 'script'
        }
      }, nodes

      assert.same trim([[
          <hr ID="divider" allowFullscreen />
          &Aacute
          <img src="" alt="" aria-hidden=true>
          </div>
      ]]), trim(nodes[1]\inner_html!)

    describe "optional_tags", ->
      visit_html = (html) ->
        result = {}
        scan_html html, (stack) ->
          table.insert result, flatten_html stack\current!\outer_html!


        -- also verify that text nodes don't mess anything up
        result_with_text_nodes = {}
        scan_html(
          html
          (stack) ->
            return if stack\current!.type == "text_node"
            table.insert result_with_text_nodes, flatten_html stack\current!\outer_html!
          text_nodes: true
        )

        assert.same result, result_with_text_nodes, "text nodes should not produce different result for optional_tags"

        result

      it "autocloses for simple table", ->
        result = visit_html [[
          <table>
            <tr>
              <td>Hello
            <tr>
              <td>world
          </table>
        ]]

        assert.same {
          "<td>Hello"
          "<tr><td>Hello"
          "<td>world"
          "<tr><td>world"
          "<table><tr><td>Hello<tr><td>world</table>"
        }, result

      it "autocloses for simple list with p tag", ->
        result = visit_html [[
          <ol>
            <li>k
            <li>
              <p>First
              <p>Second
            <li>Another</li>
          </ol>
        ]]

        assert.same {
          "<li>k"
          "<p>First"
          "<p>Second"
          "<li><p>First<p>Second"
          "<li>Another</li>"
          "<ol><li>k<li><p>First<p>Second<li>Another</li></ol>"
        }, result


      it "autocloses for larger table", ->
        result = visit_html [[
          <table cellpadding=5>
             <tr>
                <td align=center>#6
                <td>Theme
                <td align=right>4.21
             <tr>
                <td align=center>#6
                <td>Audio
                <td align=right>3.56
            </table>
        ]]

        assert.same {
          "<td align=center>#6",
          "<td>Theme",
          "<td align=right>4.21"
          "<tr><td align=center>#6<td>Theme<td align=right>4.21",
          "<td align=center>#6"
          "<td>Audio"
          "<td align=right>3.56"
          "<tr><td align=center>#6<td>Audio<td align=right>3.56"
          "<table cellpadding=5><tr><td align=center>#6<td>Theme<td align=right>4.21<tr><td align=center>#6<td>Audio<td align=right>3.56</table>",
        }, result

      -- this is parsed incorrectly with the p tag
      it "list with optional tags for li", ->
        result = visit_html [[
          <ol id=outer>
            <li>
              <ol id=inner>
                <li>k
                <li>
                  <p>First
                  <p>Second
                <li>Another
              </ol>
            <li>Good work
          </ol>
        ]]

        assert.same {
          "<li>k"
          "<p>First"
          "<p>Second"
          "<li><p>First<p>Second"
          "<li>Another"
          "<ol id=inner><li>k<li><p>First<p>Second<li>Another</ol>"
          "<li><ol id=inner><li>k<li><p>First<p>Second<li>Another</ol>"
          "<li>Good work"
          "<ol id=outer><li><ol id=inner><li>k<li><p>First<p>Second<li>Another</ol><li>Good work</ol>"
        }, result

      it "a more complicated example", ->
        result = visit_html [[
          <ol id=outer>
            <li>
              <ol id=inner>
                <li> um
                <li>
                  <ol id=more>
                    <li>one
                    <li>
                      <tr>
                        <td>
                          <p> yo
                  </ol>
              </ol>
            <li>
              <p>First
              <p>Second
            <li>Good work
          </ol>
        ]]

        assert.same {
          '<li> um'
          '<li>one'
          '<p> yo'
          '<td><p> yo'
          '<tr><td><p> yo'
          '<li><tr><td><p> yo'
          '<ol id=more><li>one<li><tr><td><p> yo</ol>'
          '<li><ol id=more><li>one<li><tr><td><p> yo</ol>'
          '<ol id=inner><li> um<li><ol id=more><li>one<li><tr><td><p> yo</ol></ol>'
          '<li><ol id=inner><li> um<li><ol id=more><li>one<li><tr><td><p> yo</ol></ol>'
          '<p>First'
          '<p>Second'
          '<li><p>First<p>Second'
          '<li>Good work'
          '<ol id=outer><li><ol id=inner><li> um<li><ol id=more><li>one<li><tr><td><p> yo</ol></ol><li><p>First<p>Second<li>Good work</ol>'
        }, result

    describe "text_nodes", ->
      it "scans text nodes", ->
        text_nodes = {}

        scan_html(
          "hello <span>world</span>"

          (stack) ->
            node = stack\current!
            if node.type == "text_node"
              table.insert text_nodes, node\inner_html!

          text_nodes: true
        )

        assert.same {
          "hello "
          "world"
        }, text_nodes

      it "text nodes and invalid close tag", ->
        result = {}

        scan_html(
          "<a>one</a></a></b>hi"

          (stack) ->
            table.insert result, stack\current!\outer_html!

          text_nodes: true
        )

        assert.same {
          "one"
          "<a>one</a>"
          "</a>"
          "</b>hi"
        }, result

      it "scans text nodes with cdata", ->
        result = {}

        scan_html(
          "
            hello
            <div>
              <![CDATA[hello from <div> thing]]>
            </div>
            world
          "
          (stack) ->
            node = stack\current!
            switch node.type
              when "text_node"
                table.insert result, {
                  tag: node.tag
                  len: #node\outer_html!
                  inner: trim(node\inner_html!)
                  outer: trim(node\outer_html!)
                  num: node.num
                }
              else
                table.insert result, "tag:#{node.tag}"



          text_nodes: true
        )

        assert.same {
          {
            len: 31
            num: 1
            inner: "hello"
            outer: "hello"
            tag: ""
          }
          { -- this currently reads whitespace as text node
            len: 15
            num: 1
            inner: ""
            outer: ""
            tag: ""
          }
          {
            len: 34,
            num: 2,
            inner: "hello from <div> thing",
            outer: [=[<![CDATA[hello from <div> thing]]>]=],
            tag: "cdata"
          }
          {
            len: 13,
            num: 3,
            inner: ""
            outer: ""
            tag: ""
          }
          "tag:div"
          {
            len: 29,
            num: 3,
            inner: "world",
            outer: "world",
            tag: ""
          }
        }, result

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

    it "replaces consecutive tags" , ->
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

    it "replaces attributes with boolean attribute", ->
      out = replace_html "<iframe></iframe>", (stack) ->
        stack\current!\replace_attributes {
          allowfullscreen: true
        }

      assert.same "<iframe allowfullscreen></iframe>", out

    it "replaces attributes on void tag", ->
      out = replace_html "<div><hr /></div>", (stack) ->
        return unless stack\is "hr"
        stack\current!\replace_attributes {
          cool: "zone"
        }

      assert.same '<div><hr cool="zone" /></div>', out

      out = replace_html "<div><hr></div>", (stack) ->
        return unless stack\is "hr"
        stack\current!\replace_attributes {
          cool: "zone"
        }

      assert.same '<div><hr cool="zone"></div>', out


    it "replaces content in text nodes", ->
      out = replace_html(
        "hello XX <span>worXXld</span>"

        (stack) ->
          node = stack\current!
          if node.type == "text_node"
            node\replace_outer_html node\outer_html!\gsub "XX", "leafo"

        text_nodes: true
      )

      assert.same "hello leafo <span>worleafold</span>", out

    it "text nodes can't have attributes updated", ->
      out = replace_html(
        "hello world <![CDATA[hi]]>"

        (stack) ->
          node = stack\current!
          assert.has_error(
            -> node\replace_attributes { umm: "what" }
            "replace_attributes: text nodes have no attributes"
          )

        text_nodes: true
      )

      assert.same "hello world <![CDATA[hi]]>", out

    it "converts links", ->
      out = replace_html(
        "one http://leafo and <a href='http://doop'>http://woop <span>http://oop</span></a>"

        (stack) ->
          node = stack\current!
          if node.type == "text_node" and not stack\is("a *, a")
            node\replace_outer_html node\outer_html!\gsub "(http://[^ <\"']+)", "<a href=\"%1\">%1</a>"

        text_nodes: true
      )

      assert.same [[one <a href="http://leafo">http://leafo</a> and <a href='http://doop'>http://woop <span>http://oop</span></a>]], out

    describe "update attributes", ->
      it "basic update", ->
        out = replace_html '<div a="b" b="c" a="whw" b="&amp;&quot;"></div>', (stack) ->
          node = stack\current!

          node\update_attributes {
            color: "green"
          }

        assert.same [[<div a="b" b="c" a="whw" b="&amp;&quot;" color="green"></div>]], out

      it "updates self closing tag with duplicates", ->
        out = replace_html '<img src="" src="efjef" alt="" />', (stack) ->
          node = stack\current!

          node\update_attributes {
            src: "http://leafo.net/hi.png"
          }

        assert.same [[<img alt="" src="http://leafo.net/hi.png" />]], out


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
