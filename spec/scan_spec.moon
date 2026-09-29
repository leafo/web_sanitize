
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

    it "doesn't provide edit methods", ->
      scan_html "<b>x</b>", (stack) ->
        node = stack\current!
        for method in *{"replace_attributes", "update_attributes", "replace_inner_html", "replace_outer_html", "unwrap"}
          assert.is_nil node[method], method

    it "scans a < that doesn't start a tag as text", ->
      nodes = (html) ->
        out = {}
        scan_html html, ((stack) ->
          node = stack\current!
          table.insert out, "#{node.tag}=#{node\outer_html!}"
        ), text_nodes: true
        out

      assert.same {"=<", 'img=<img src="x">'}, nodes '<<img src="x">'
      assert.same {"=a", "=<", 'img=<img src="x">', 'div=<div>a<<img src="x"></div>'}, nodes '<div>a<<img src="x"></div>'
      assert.same {"=a", "=<", "=<b", "=<"}, nodes "a<<b<"
      assert.same {"=1 ", "=<", "=< 2", "p=<p>1 << 2</p>", "=<"}, nodes "<p>1 << 2</p><"

    it "treats closing tags that aren't open as text", ->
      result = {}

      scan_html "<div>a</span>b</b></div></div>", ((stack) ->
        node = stack\current!
        table.insert result, node\outer_html!
      ), text_nodes: true

      assert.same {
        "a"
        "</span>b"
        "</b>"
        "<div>a</span>b</b></div>"
        "</div>"
      }, result

    it "closes the nearest open tag with a matching name", ->
      result = {}

      scan_html "<div><div>x</div>y</div>", (stack) ->
        table.insert result, stack\current!\outer_html!

      assert.same {
        "<div>x</div>"
        "<div><div>x</div>y</div>"
      }, result

    it "matches closing tags case insensitively", ->
      result = {}

      scan_html "<DIV><b>x</div>y</B>", (stack) ->
        table.insert result, stack\current!\outer_html!

      assert.same {
        "<b>x"
        "<DIV><b>x</div>"
      }, result

    it "scans CDATA without a closing marker as text", ->
      nodes = (html) ->
        out = {}
        scan_html html, ((stack) ->
          node = stack\current!
          table.insert out, "#{node.tag}=#{node\outer_html!}"
        ), text_nodes: true
        out

      assert.same {"cdata=<![CDATA[x]]>", "=<![CDATA[y"}, nodes "<![CDATA[x]]><![CDATA[y"
      assert.same {"cdata=<![CDATA[]]>", "=z", "=<![CDATA["}, nodes "<![CDATA[]]>z<![CDATA["
      assert.same {"cdata=<![CDATA[a<![CDATA[b]]>"}, nodes "<![CDATA[a<![CDATA[b]]>"

    it "scans deep stack followed by unmatched closing tags", ->
      html = string.rep("<div>", 2000) .. string.rep("</span>", 2000)
      visited = 0
      outermost = nil

      scan_html html, (stack) ->
        visited += 1
        outermost = stack\current!\outer_html! if #stack == 1

      assert.same 2000, visited
      assert.same html, outermost

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


    it "scans markup after a self closing raw text tag", ->
      visited = (html) ->
        out = {}
        scan_html html, (stack) ->
          node = stack\current!
          table.insert out, "#{node.tag}=#{node\outer_html!}"
        out

      assert.same {"script=<script />"}, visited "<script />x</b>"
      assert.same {"style=<style/>"}, visited "<style/>a</p>"
      assert.same {
        "script=<script />"
        "b=<b>y</b>"
        "div=<div><script />x<b>y</b></div>"
      }, visited "<div><script />x<b>y</b></div>"

      assert.same {
        "textarea=<TEXTAREA/>"
        "i=<i>z</i>"
      }, visited "<TEXTAREA/><i>z</i>"

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

      it "autocloses improperly nested element in p tag", ->
        result = visit_html [[
          <p>
            <div>What the heck is going on here</div>
            <span>hi</span>
          </p>
        ]]

        assert.same {
          "<p>"
          "<div>What the heck is going on here</div>"
          "<span>hi</span>"
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

      it "optgroup and options", ->
        result = visit_html [[
          <select>
            <optgroup label="things">
              <option>ice
              <option>cube
            <optgroup label="frogs">
              <option>green
              <option>blue
          </select>
        ]]

        assert.same {
          '<option>ice'
          '<option>cube'
          '<optgroup label="things"><option>ice<option>cube'
          '<option>green'
          '<option>blue'
          '<optgroup label="frogs"><option>green<option>blue'
          '<select><optgroup label="things"><option>ice<option>cube<optgroup label="frogs"><option>green<option>blue</select>'
        }, result

      it "example from html spec", ->
        -- markup example from https://html.spec.whatwg.org/multipage/syntax.html#optional-tags
        result = visit_html [[
          <table>
           <caption>37547 TEE Electric Powered Rail Car Train Functions (Abbreviated)
           <colgroup><col><col><col>
           <thead>
            <tr> <th>Function                              <th>Control Unit     <th>Central Station
           <tbody>
            <tr> <td>Headlights                            <td>✔                <td>✔
            <tr> <td>Interior Lights                       <td>✔                <td>✔
            <tr> <td>Electric locomotive operating sounds  <td>✔                <td>✔
            <tr> <td>Engineer's cab lighting               <td>                 <td>✔
            <tr> <td>Station Announcements - Swiss         <td>                 <td>✔
          </table>
        ]]

        assert.same {
          '<caption>37547 TEE Electric Powered Rail Car Train Functions (Abbreviated)'
          '<col>'
          '<col>'
          '<col>'
          '<colgroup><col><col><col>'
          '<th>Function'
          '<th>Control Unit'
          '<th>Central Station'
          '<tr><th>Function<th>Control Unit<th>Central Station'
          '<thead><tr><th>Function<th>Control Unit<th>Central Station'
          '<td>Headlights'
          '<td>✔'
          '<td>✔'
          '<tr><td>Headlights<td>✔<td>✔'
          '<td>Interior Lights'
          '<td>✔'
          '<td>✔'
          '<tr><td>Interior Lights<td>✔<td>✔'
          '<td>Electric locomotive operating sounds'
          '<td>✔'
          '<td>✔'
          '<tr><td>Electric locomotive operating sounds<td>✔<td>✔'
          "<td>Engineer's cab lighting"
          '<td>'
          '<td>✔'
          "<tr><td>Engineer's cab lighting<td><td>✔"
          '<td>Station Announcements - Swiss'
          '<td>'
          '<td>✔'
          "<tr><td>Station Announcements - Swiss<td><td>✔"

          "<tbody><tr><td>Headlights<td>✔<td>✔<tr><td>Interior Lights<td>✔<td>✔<tr><td>Electric locomotive operating sounds<td>✔<td>✔<tr><td>Engineer's cab lighting<td><td>✔<tr><td>Station Announcements - Swiss<td><td>✔"

          "<table><caption>37547 TEE Electric Powered Rail Car Train Functions (Abbreviated)<colgroup><col><col><col><thead><tr><th>Function<th>Control Unit<th>Central Station<tbody><tr><td>Headlights<td>✔<td>✔<tr><td>Interior Lights<td>✔<td>✔<tr><td>Electric locomotive operating sounds<td>✔<td>✔<tr><td>Engineer's cab lighting<td><td>✔<tr><td>Station Announcements - Swiss<td><td>✔</table>"

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

    it "raises an error when replacing the html of an open ancestor", ->
      for method in *{"replace_inner_html", "replace_outer_html"}
        assert.has_error(
          ->
            replace_html "<div><b>x</b></div>", (stack) ->
              if #stack > 1
                stack[1][method] stack[1], "y"
          "#{method}: element is still open, replace its HTML from its own callback"
        )

    it "edits elements after a < that doesn't start a tag", ->
      remove_images = (html) ->
        replace_html html, (stack) ->
          node = stack\current!
          node\replace_outer_html "" if node.tag == "img"

      assert.same "<div>a<</div>", remove_images '<div>a<<img src="x"></div>'
      assert.same " b <", remove_images '<img src="x"> b <'
      assert.same "<div>1 << 2</div>", remove_images '<img src="x"><div>1 << 2</div>'

    it "unwraps an element, keeping edits to its children", ->
      out = replace_html [[<p>hi <font color="red">see <img src="a.png"> and <span class="q">quote</span></font></p>]], (stack) ->
        node = stack\current!
        if stack\is "span.q"
          node\replace_attributes { class: "c" }

        if stack\is "img"
          node\replace_outer_html "[Image #{node.attr.src}]"

        if stack\is "font"
          node\unwrap!

      assert.same [[<p>hi see [Image a.png] and <span class="c">quote</span></p>]], out

    it "unwraps elements without a closing tag", ->
      unwrap = (html, query) ->
        replace_html html, (stack) ->
          stack\current!\unwrap! if stack\is query

      assert.same "abc", unwrap "a<br>b<img src=x />c", "br, img"
      assert.same "onetwo", unwrap "<p>one<p>two", "p"
      assert.same "ab", unwrap "<div>a<b>b", "div, b"
      assert.same "<div>x</div>y", unwrap "<div><b>x</div>y", "b"
      assert.same "xy", unwrap "<div><div>x</div>y</div>", "div"
      assert.same "x", unwrap "<DIV class=a>x</div >", "div"

    it "raises an error when unwrapping a text node or an open ancestor", ->
      assert.has_error(
        -> replace_html "hi", ((stack) -> stack\current!\unwrap!), text_nodes: true
        "unwrap: text nodes have no tags"
      )

      assert.has_error(
        ->
          replace_html "<div><b>x</b></div>", (stack) ->
            stack[1]\unwrap! if #stack > 1
        "unwrap: element is still open, unwrap it from its own callback"
      )

    it "raises an error when editing a node after replace_outer_html or unwrap", ->
      edits = {
        replace_attributes: (node) -> node\replace_attributes { class: "z" }
        update_attributes: (node) -> node\update_attributes { class: "z" }
        replace_inner_html: (node) -> node\replace_inner_html "y"
        replace_outer_html: (node) -> node\replace_outer_html "Z"
        unwrap: (node) -> node\unwrap!
      }

      for first in *{"replace_outer_html", "unwrap"}
        for method, edit in pairs edits
          assert.has_error(
            ->
              replace_html "<b>x</b>rest", (stack) ->
                node = stack\current!
                edits[first] node
                edit node
            "#{method}: can't edit a node after replace_outer_html or unwrap"
          )

    it "raises an error for an edit inside text an earlier edit replaced", ->
      saved = nil
      assert.has_error(
        ->
          replace_html "<div><b>x</b></div>", (stack) ->
            node = stack\current!
            saved = node if node.tag == "b"
            if node.tag == "div"
              node\replace_outer_html "<p>y</p>"
              saved\replace_attributes { class: "z" }
        "replace_html: an edit overlaps text replaced by an earlier edit, only edit the current node from its own callback"
      )

    it "allows edits before replace_outer_html or unwrap", ->
      assert.same "xrest", replace_html "<b>x</b>rest", (stack) ->
        node = stack\current!
        node\update_attributes { class: "z" }
        node\unwrap!

      assert.same "yrest", replace_html "<b>x</b>rest", (stack) ->
        node = stack\current!
        node\replace_inner_html "y"
        node\unwrap!

      assert.same "Zrest", replace_html "<b>x</b>rest", (stack) ->
        node = stack\current!
        node\replace_attributes {}
        node\replace_outer_html "Z"

    it "unwraps a self closing element", ->
      assert.same "ab", replace_html "a<div />b", (stack) ->
        stack\current!\unwrap!

    it "replaces parent attributes after child content", ->
      out = replace_html '<a href="x"><b>hi</b></a> <a><b>there</b></a>', (stack) ->
        node = stack\current!
        switch node.tag
          when "b"
            node\replace_inner_html node\inner_html!\upper!
          when "a"
            node\replace_attributes { rel: "nofollow" }

      assert.same '<a rel="nofollow"><b>HI</b></a> <a rel="nofollow"><b>THERE</b></a>', out

    it "replaces attributes and content of the same node", ->
      out = replace_html '<div class="a">hello</div><div>world</div>', (stack) ->
        node = stack\current!
        node\replace_attributes { id: "x" }
        node\replace_inner_html "bye"

      assert.same '<div id="x">bye</div><div id="x">bye</div>', out

    it "discards child changes when parent outer html is replaced", ->
      out = replace_html "<div><span>a</span><span>b</span></div><p>c</p>", (stack) ->
        node = stack\current!
        switch node.tag
          when "span"
            node\replace_inner_html "changed"
          when "div"
            node\replace_outer_html "[#{node\outer_html!}]"

      assert.same "[<div><span>a</span><span>b</span></div>]<p>c</p>", out

    it "replaces content next to deleted tags", ->
      out = replace_html "<img><b>x</b><img><i></i><img>", (stack) ->
        node = stack\current!
        switch node.tag
          when "img"
            node\replace_outer_html ""
          when "i"
            node\replace_inner_html "hi"

      assert.same "<b>x</b><i>hi</i>", out

    it "inserts into empty tags", ->
      out = replace_html "<code></code><code></code>", (stack) ->
        node = stack\current!
        node\replace_inner_html "hi"
        node\replace_attributes { x: "1" }

      assert.same '<code x="1">hi</code><code x="1">hi</code>', out

      out = replace_html "<code></code>", (stack) ->
        node = stack\current!
        node\replace_attributes { x: "1" }
        node\replace_inner_html "hi"

      assert.same '<code x="1">hi</code>', out

    it "replaces adjacent tags with equal length content", ->
      out = replace_html "<b>1</b><i>2</i><br/>", (stack) ->
        node = stack\current!
        switch node.tag
          when "b"
            node\replace_outer_html "<u>1</u>"
          when "i"
            node\replace_outer_html "<s>2</s>"
          when "br"
            node\replace_outer_html "<hr/>"

      assert.same "<u>1</u><s>2</s><hr/>", out

    it "replaces many tags", ->
      html = string.rep '<img src="data:x">text ', 2000
      out = replace_html html, (stack) ->
        node = stack\current!
        if node.tag == "img"
          node\replace_outer_html ""

      assert.same string.rep("text ", 2000), out

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

      it "keeps boolean attributes", ->
        out = replace_html '<iframe disabled src="x"></iframe>', (stack) ->
          stack\current!\update_attributes { title: "t" }

        assert.same [[<iframe disabled src="x" title="t"></iframe>]], out

      it "replaces attributes with a boolean attribute tuple", ->
        out = replace_html '<iframe></iframe>', (stack) ->
          stack\current!\replace_attributes { {"readonly"}, {"src", "x"} }

        assert.same [[<iframe readonly src="x"></iframe>]], out

  describe "_apply_changes", ->
    import _apply_changes from require "web_sanitize.query.scan_html"

    it "applies disjoint deletions", ->
      assert.same "tt", _apply_changes "<img>t<img>t", {
        {1, 6, ""}
        {7, 12, ""}
      }

    it "applies parent attributes after child content", ->
      assert.same '<a rel="n"><b>HI</b></a>', _apply_changes '<a href="x"><b>hi</b></a>', {
        {16, 18, "HI"}
        {1, 13, '<a rel="n">'}
      }

    it "keeps insertion when deletion collapses a range", ->
      assert.same "<div>parentnew</div>", _apply_changes "<div>a<b>x</b></div>", {
        {7, 15, ""}
        {7, 15, "new"}
        {6, 15, "parent"}
      }

    it "returns nil for changes it can't apply", ->
      assert.same nil, (_apply_changes "abcdef", { {1, 6, "X"}, {3, 4, "Y"} })
      assert.same nil, (_apply_changes "abcdef", { {4, 2, "X"} })
      assert.same nil, (_apply_changes "abcdef", { {1, 9, "X"} })


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
