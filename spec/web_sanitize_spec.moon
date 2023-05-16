-- tests pulled from:
-- * https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet

unpack = unpack or table.unpack

tests = {
  {
    "this string has no html"
    "this string has no html"
  }

  {
    '<li><i>Hello world</i></li>'
    '<li><i>Hello world</i></li>'
  }

  {
    '<li><i>Hello world</li>'
    '<li><i>Hello world</i></li>'
  }

  {
    '<!-- comment -->Hello'
    '&lt;!-- comment --&gt;Hello'
  }

  {
    '<pre/>'
    '&lt;pre/&gt;'
  }

  {
    '<h1 title="yes"></h1>'
    '<h1 title="yes"></h1>'
  }

  {
    "<h1 title='yes'></h1>"
    "<h1 title='yes'></h1>"
  }

  {
    "<h1 title=yes></h1>"
    '<h1 title=yes></h1>'
  }

  {
    "<h1 TITLE=yes></h1>"
    '<h1 TITLE=yes></h1>'
  }

  {
    [[<div title="hello world"></div>]]
    [[<div title="hello world"></div>]]
  }

  {
    [[<div title="hello world" ></div>]]
    [[<div title="hello world" ></div>]]
  }

  {
    '<a href="http://leafo.net"></a>'
    '<a href="http://leafo.net" rel="nofollow"></a>'
  }

  {
    '<a href="https://leafo.net"></a>'
    '<a href="https://leafo.net" rel="nofollow"></a>'
  }

  {
    '<a href="mailto:someone@example.com">Send email</a>'
    '<a href="mailto:someone@example.com" rel="nofollow">Send email</a>'
  }

  {
    '<a href="//leafo.net"></a>'
    '<a href="//leafo.net" rel="nofollow"></a>'
  }


  {
    'hello <script dad="world"><b>yes</b></b>'
    'hello &lt;script dad=&quot;world&quot;&gt;<b>yes</b>&lt;/b&gt;'
  }

  {
    "<IMG color='red'></IMG>"
    '<IMG></IMG>'
  }

  {
    "<br>"
    '<br>'
  }

  {
    "<pre><br><img></pre>"
    '<pre><br><img></pre>'
  }


  -- already escaped
  {
    "hello &amp; world"
    "hello &amp; world"
  }

  {
    "&#x27; &#x2F; &#x2f; &#65;"
    "&#x27; &#x2F; &#x2f; &#65;"
  }

  -- attribute value escaping
  {
    "<img><span title='</img><script>Hello world</script'></span>"
    "<img><span title='&lt;/img&gt;&lt;script&gt;Hello world&lt;/script'></span>"
  }

  -- xss

  {
    '<SCRIPT SRC=http://ha.ckers.org/xss.js></SCRIPT>'
    '&lt;SCRIPT SRC=http://ha.ckers.org/xss.js&gt;&lt;/SCRIPT&gt;'
  }

  {
    [[<IMG SRC="javascript:alert('XSS');">]]
    '<IMG>'
  }

  {
    "<IMG SRC=javascript:alert('XSS')>"
    '&lt;IMG SRC=javascript:alert(&#x27;XSS&#x27;)&gt;'
  }

  {
    "<IMG SRC=JaVaScRiPt:alert('XSS')>"
    '&lt;IMG SRC=JaVaScRiPt:alert(&#x27;XSS&#x27;)&gt;'
  }

  {
    [[<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>]]
    '&lt;IMG SRC=`javascript:alert(&quot;RSnake says, &#x27;XSS&#x27;&quot;)`&gt;'
  }

  {
    '<IMG """><SCRIPT>alert("XSS")</SCRIPT>">'
    '&lt;IMG &quot;&quot;&quot;&gt;&lt;SCRIPT&gt;alert(&quot;XSS&quot;)&lt;/SCRIPT&gt;&quot;&gt;'
  }

  {
    '<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>'
    '&lt;IMG SRC=javascript:alert(String.fromCharCode(88,83,83))&gt;'
  }


  {
    [[<IMG SRC=# onmouseover="alert('xxs')">]]
    '&lt;IMG SRC=# onmouseover=&quot;alert(&#x27;xxs&#x27;)&quot;&gt;'
  }

  {
    [[<IMG SRC= onmouseover="alert('xxs')">]]
    '&lt;IMG SRC= onmouseover=&quot;alert(&#x27;xxs&#x27;)&quot;&gt;'
  }

  {
    [[<IMG onmouseover="alert('xxs')">]]
    '<IMG>'
  }

  {
    [[<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;
&#39;&#88;&#83;&#83;&#39;&#41;>]]
    [[&lt;IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;
&#39;&#88;&#83;&#83;&#39;&#41;&gt;]]
  }

  {
    [[<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&
#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>]]
    [[&lt;IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&amp;
#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041&gt;]]
  }

  {
    [[<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>]]
    [[&lt;IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29&gt;]]
  }

  {
    [[<IMG SRC="jav	ascript:alert('XSS');">]]
    '<IMG>'
  }

  {
    [[<IMG SRC="jav&#x09;ascript:alert('XSS');">]]
    '<IMG>'
  }

  {
    '<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>'
    '&lt;SCRIPT/XSS SRC=&quot;http://ha.ckers.org/xss.js&quot;&gt;&lt;/SCRIPT&gt;'
  }

  {
    [[<BODY onload!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>]]
    [[&lt;BODY onload!#$%&amp;()*~+-_.,:;?@[/|\]^`=alert(&quot;XSS&quot;)&gt;]]
  }

  {
    '<SCRIPT/SRC="http://ha.ckers.org/xss.js"></SCRIPT>'
    '&lt;SCRIPT/SRC=&quot;http://ha.ckers.org/xss.js&quot;&gt;&lt;/SCRIPT&gt;'
  }

  {
    '<<SCRIPT>alert("XSS");//<</SCRIPT>'
    '&lt;&lt;SCRIPT&gt;alert(&quot;XSS&quot;);//&lt;&lt;/SCRIPT&gt;'
  }

  {
    [[<IMG SRC="javascript:alert('XSS')"]]
    '&lt;IMG SRC=&quot;javascript:alert(&#x27;XSS&#x27;)&quot;'
  }

  {
    [[<INPUT TYPE="IMAGE" SRC="javascript:alert('XSS');">]]
    '&lt;INPUT TYPE=&quot;IMAGE&quot; SRC=&quot;javascript:alert(&#x27;XSS&#x27;);&quot;&gt;'
  }

  {
    [[<IMG DYNSRC="javascript:alert('XSS')">]]
    '<IMG>'
  }

  {
    [[<STYLE>li {list-style-image: url("javascript:alert('XSS')");}</STYLE><UL><LI>XSS</br>]]
    '&lt;STYLE&gt;li {list-style-image: url(&quot;javascript:alert(&#x27;XSS&#x27;)&quot;);}&lt;/STYLE&gt;<UL><LI>XSS&lt;/br&gt;</li></ul>'
  }

  {
    [[<IMG SRC='vbscript:msgbox("XSS")'>]]
    '<IMG>'
  }

  {
    [[<BR SIZE="&{alert('XSS')}">]]
    '<BR>'
  }

  {
    [[<LINK REL="stylesheet" HREF="javascript:alert('XSS');">]]
    '&lt;LINK REL=&quot;stylesheet&quot; HREF=&quot;javascript:alert(&#x27;XSS&#x27;);&quot;&gt;'
  }

  {
    [[<STYLE>@import'http://ha.ckers.org/xss.css';</STYLE>]]
    '&lt;STYLE&gt;@import&#x27;http://ha.ckers.org/xss.css&#x27;;&lt;/STYLE&gt;'
  }

  {
    [[<META HTTP-EQUIV="Link" Content="<http://ha.ckers.org/xss.css>; REL=stylesheet">]]
    '&lt;META HTTP-EQUIV=&quot;Link&quot; Content=&quot;&lt;http://ha.ckers.org/xss.css&gt;; REL=stylesheet&quot;&gt;'
  }

  {
    [[<META HTTP-EQUIV="refresh" CONTENT="0;url=javascript:alert('XSS');">]]
    '&lt;META HTTP-EQUIV=&quot;refresh&quot; CONTENT=&quot;0;url=javascript:alert(&#x27;XSS&#x27;);&quot;&gt;'
  }

  {
    [[<IFRAME SRC="javascript:alert('XSS');"></IFRAME>]]
    '&lt;IFRAME SRC=&quot;javascript:alert(&#x27;XSS&#x27;);&quot;&gt;&lt;/IFRAME&gt;'
  }

  {
    [[<FRAMESET><FRAME SRC="javascript:alert('XSS');"></FRAMESET>]]
    '&lt;FRAMESET&gt;&lt;FRAME SRC=&quot;javascript:alert(&#x27;XSS&#x27;);&quot;&gt;&lt;/FRAMESET&gt;'
  }

  {
    [[<TABLE BACKGROUND="javascript:alert('XSS')">]]
    '<TABLE></table>'
  }

  {
    [[<iframe src=http://ha.ckers.org/scriptlet.html <]]
    '&lt;iframe src=http://ha.ckers.org/scriptlet.html &lt;'
  }

  -- malformed

  {
    "<b color=red>hi</b wazzaup"
    '<b>hi&lt;/b wazzaup</b>'
  }

  {
    "<b title='yeah'"
    '&lt;b title=&#x27;yeah&#x27;'
  }

  {
    [[<div><p somethign="world" / </div>]]
    "<div>&lt;p somethign=&quot;world&quot; / </div>"
  }

  -- self closing tags
  -- Note: Div is not a valid self closing tag, so we block it

  {
    "<div />"
    "&lt;div /&gt;"
  }

  {
    "<div/>"
    "&lt;div/&gt;"
  }

  {
    "<div/ >"
    "&lt;div/ &gt;"
  }

  {
    "<div\t/ \t>"
    "&lt;div\t/ \t&gt;"
  }

  {
    "<br />"
    "<br />"
  }

  {
    "<br/>"
    "<br/>"
  }

  {
    "<br/ >"
    "<br/ >"
  }

  {
    "<br\t/ \t>"
    "<br\t/ \t>"
  }

  {
    "<link />"
    "&lt;link /&gt;"
  }


  -- closing tags whitespace
  {
    [[<div>< /div>]]
    [[<div>< /div>]]
  }

  {
    [[<div></ div>]]
    [[<div></ div>]]
  }

  {
    [[<div>< / div>]]
    [[<div>< / div>]]
  }

  -- opening tag whitespace
  {
    [[< div></div>]]
    [[< div></div>]]
  }

  {
    [[<div ></div>]]
    [[<div ></div>]]
  }

  {
    [[<div   dir = "ltr" height=429  ></div>]]
    [[<div   dir = "ltr"  ></div>]]
  }

  -- comments
  {
    -- not ideal but it works
    'some<!-- <div> -->world'
    "some&lt;!-- <div> --&gt;world</div>"
  }

  {
    "<div on<!--  -->click='alert(1)'></div>"
    [[&lt;div on&lt;!--  --&gt;click=&#x27;alert(1)&#x27;&gt;&lt;/div&gt;]]
  }

  {
    [[<div attr="<!-- m -->"></div>]]
    "<div></div>"
  }

  {
    -- comments do not work in attributes
    [[<div lang="<!-- " onclick="alert(4) -->"></div>]]
    [[<div lang="&lt;!-- "></div>]]
  }
}

extract_text_tests = {
  -- test syntax:
  -- {
  --   1: the input
  --   2: the html output
  --   3: the plain text output (falls back to html if nil)
  --   4: the printable plain text output (falls back to plain output if nil)
  -- }

  {
    "hello world"
    "hello world"
  }

  {
    "<b title='yeah'"
    '&lt;b title=&#x27;yeah&#x27;'
    "<b title='yeah'"
  }

  {
    "<p> what the heck </p> <br /> is going on"
    'what the heck is going on'
  }

  {
    "<b color=red>hi</b wazzaup"
    'hi&lt;/b wazzaup'
    "hi</b wazzaup"
  }

  {
    [[<TABLE BACKGROUND="javascript:alert('XSS')">]]
    ''
  }

  {
    "this string has no html"
    "this string has no html"
  }

  {
    '<li><i>Hello world</i></li>'
    'Hello world'
  }

  {
    '<li><i>Hello world</li>'
    'Hello world'
  }

  {
    '<!-- comment -->Hello'
    'Hello'
  }

  {
    'some<!-- <div> -->world'
    'someworld'
  }

  {
    'hello <script dad="world"><b>yes</b></b>'
    'hello yes'
  }

  {
    "Hello &copy; world"
    "Hello &copy; world"
    "Hello © world"
  }

  {
    "&cent&cent;&lthi&lt;"
    "&cent&cent;&lthi&lt;"
    "¢¢&lthi<"
  }

  {
    "&amp; &copy; &fart; &#x00A9; &#xA9; &#169; &#x22D9; &#x22d9; &#8921; < > <hello/> world"
    "&amp; &copy; &fart; &#x00A9; &#xA9; &#169; &#x22D9; &#x22d9; &#8921; &lt; &gt; world"
    "& © &fart; © © © ⋙ ⋙ ⋙ < > world"
  }

  {
    "&#1;" -- add one with optional ;
    "&#1;"
    "\1"
    ""
  }

  {
    "&#2;&#3;"
    "&#2;&#3;"
    "\2\3"
    ""
  }

  {
    "&#xF;"
    "&#xF;"
    "\15"
    ""
  }

  {
    "&#16;&#15;hi "
    "&#16;&#15;hi"
    "\016\015hi"
    "hi"
  }

  {
    "\t\n<div> <ul> <li></li>\r\n<li></li> </ul> </div>"
    ""
  }


  {
    "&nbsp; &nbsp;hello &nbsp;\n&nbsp; world &nbsp;"
    "&nbsp; &nbsp;hello &nbsp; &nbsp; world &nbsp;"
    "hello world"
  }

  {
    ""
    ""
  }

  {
    "&nbsp;for designing the art for this jam! ♥"
    "&nbsp;for designing the art for this jam! ♥"
    "for designing the art for this jam! ♥"
  }

}

sanitize_tests_strip = {
  {
    [[<body><b>hello world</b></body>]]
    "<b>hello world</b>"
  }

  {
    "this string has no html"
    "this string has no html"
  }

  {
    [[<TABLE BACKGROUND="javascript:alert('XSS')">]]
    "<TABLE></table>"
  }

  {
    '<li><i>Hello world</li>'
    '<li><i>Hello world</i></li>'
  }

  {
    '<!-- comment -->Hello'
    '&lt;!-- comment --&gt;Hello'
  }

  {
    'hello <script dad="world"><b>yes</b></b>'
    'hello <b>yes</b>'
  }

  {
    [[<iframe src=http://ha.ckers.org/scriptlet.html <]]
    '&lt;iframe src=http://ha.ckers.org/scriptlet.html &lt;'
  }
}

sanitize_tests_strip_comments = {
  {
    'some<!-- <div> -->world'
    "someworld"
  }
  {
    "<s<!-- html comment  -->trong>test</strong>"
    "&lt;strong&gt;test&lt;/strong&gt;"
  }

  {
    "<<!-- html comment  -->strong>test</strong>"
    "&lt;strong&gt;test&lt;/strong&gt;"
  }

  {
    "<div on<!--  -->click='alert(1)'></div>"
    [[&lt;div onclick=&#x27;alert(1)&#x27;&gt;&lt;/div&gt;]]
  }

  {
    [[<div attr="<!-- m -->"></div>]]
    [[<div></div>]]
  }

  {
    [[<div title="<!-- m -->"></div>]]
    [[<div title="&lt;!-- m --&gt;"></div>]]
  }

  {
    -- comments do not work in attributes
    [[<div lang="<!-- " onclick="alert(4) -->"></div>]]
    [[<div lang="&lt;!-- "></div>]]
  }
}


describe "web_sanitize", ->
  describe "sanitize_html", ->
    import sanitize_html from require "web_sanitize"
    for i, {input, expected} in ipairs tests
      it "#{i}: should sanitize and match: #{input}", ->
        assert.are.equal expected, sanitize_html input

  describe "extract_text", ->
    describe "to html", ->
      for i, {input, html_expected} in ipairs extract_text_tests
        it "#{i}: extract text and match", ->
          import extract_text from require "web_sanitize"
          assert.are.equal html_expected, extract_text(input)

    describe "to plain text", ->
      for i, {input, html_expected, plain_expected} in ipairs extract_text_tests
        expected = plain_expected or html_expected

        it "#{i}: extracts text", ->
          import Extractor from require "web_sanitize.html"
          extract_text = Extractor { }
          output = assert extract_text input

          assert.are.equal expected, output

    describe "to printable plain text", ->
      for i, {input, html_expected, plain_expected, printable_expected} in ipairs extract_text_tests
        expected = printable_expected or plain_expected or html_expected

        it "#{i}: extracts text", ->
          import Extractor from require "web_sanitize.html"
          extract_text = Extractor { printable: true }
          output = assert extract_text input

          assert.are.equal expected, output

  describe "sanitize_html strip tags", ->
    local sanitize_html

    setup ->
      import Sanitizer from require "web_sanitize.html"
      sanitize_html = Sanitizer strip_tags: true

    for i, {input, output} in ipairs sanitize_tests_strip
      it "#{i}: should sanitize and match", ->
        assert.are.equal output, sanitize_html input

  describe "sanitize_html strip comments", ->
    local sanitize_html

    setup ->
      import Sanitizer from require "web_sanitize.html"
      sanitize_html = Sanitizer strip_comments: true

    for i, {input, output} in ipairs sanitize_tests_strip_comments
      it "#{i}: should sanitize and match", ->
        assert.are.equal output, sanitize_html input

  describe "whitelist", ->
    whitelist = require "web_sanitize.whitelist"

    it "clones whitelist", ->
      wl = whitelist\clone!
      assert.same whitelist, wl

      wl.tags.b = nil
      assert.not.same whitelist, wl

    it "clones nested", ->
      wl = whitelist\clone!
      assert.same whitelist, wl

      wl.tags.abbr.cool = true
      assert.not.same whitelist, wl

    it "updates the metatable for tags when cloning", ->
      wl = whitelist\clone!
      wl.tags[1].cool = true

      assert.same true, wl.tags.abbr.cool
      assert.falsy whitelist.tags.abbr.cool

  describe "modified whitelist", ->
    local sanitize_html

    before_each ->
      whitelist = require("web_sanitize.whitelist")\clone!
      whitelist.tags.iframe = {
        src: true
        frameborder: true
        allowfullscreen: true
        style: (str) -> "*''#{str}''*"
      }

      import Sanitizer from require "web_sanitize.html"
      sanitize_html = Sanitizer { :whitelist }

    it "should sanitize", ->
      assert.same unpack {
        [[<iframe src="//www.youtube.com/embed/Ag1lwrY7d94?rel=0" frameborder="0" allowfullscreen></iframe>]]
        sanitize_html [[<iframe src="//www.youtube.com/embed/Ag1lwrY7d94?rel=0" frameborder="0" allowfullscreen></iframe>]]
      }

      assert.same unpack {
        [[<iframe style="*&#x27;&#x27;hello world&#x27;&#x27;*"></iframe>]]
        sanitize_html [[<iframe style="hello world">]]
      }

    it "doesn't allow self closing iframe", ->
      assert.same unpack {
        [[&lt;iframe src=&quot;&quot; frameborder=&quot;0&quot; src=&quot;http://leafo.net&quot;/&gt;]]
        sanitize_html [[<iframe src="" frameborder="0" src="http://leafo.net"/>]]
      }

    it "does not allow markup within tag attribute", ->
      assert.same(
        [[<span title="&lt;/iframe&gt;"></span>]]
        sanitize_html [[<span title="</iframe>"></span>]]
      )

  describe "inject attributes", ->
    local sanitize_html, whitelist

    before_each ->
      whitelist = require("web_sanitize.whitelist")\clone!
      import Sanitizer from require "web_sanitize.html"
      sanitize_html = Sanitizer { :whitelist }

    expect = (expected, got) ->
      if type(expected) == "table"
        for item in *expected
          return true if item == got

        error "expected #{got} to be one of {#{table.concat expected, "\n"}}"
      else
        assert.same expected, got

    it "injects string attributes on tags", =>
      whitelist.add_attributes.a = {
        hello: "world"
      }

      whitelist.add_attributes.b = {
        world: "two things"
        zone: "one more"
      }

      -- no other attributes
      expect {
        [[<a hello="world">one</a><b world="two things" zone="one more">two</b>]]
        [[<a hello="world">one</a><b zone="one more" world="two things">two</b>]]
      }, sanitize_html [[<a>one</a><b>two</b>]]

      -- has other attributes
      expect {
        [[<a title="yeah" hello="world">one</a><b title="it's here" world="two things" zone="one more">two</b>]]
        [[<a title="yeah" hello="world">one</a><b title="it's here" zone="one more" world="two things">two</b>]]
      }, sanitize_html [[<a title="yeah" color="blue">one</a><b height="10px" title="it's here">two</b>]]

    it "injects attributes on tags by function", =>
      whitelist.add_attributes.a = {
        rel: (attrs) ->
          unless (attrs.href or "")\match "itch.io"
            "nofollow noopener"
      }

      expect {
        [[<a title="good link" href="http://leafo.net" rel="nofollow noopener">heres a link</a><a href="http://itch.io">another link</a>]]
      }, sanitize_html [[<a onclick="" title="good link" href="http://leafo.net">heres a link</a><a href="http://itch.io">another link</a>]]


    it "doesn't inject attribute value that breaks markup", =>
      whitelist.add_attributes.b = {
        "world": "</iframe>"
        "zone": => "<script>"
      }

      expect {
        [[<b zone="&lt;script&gt;" world="&lt;/iframe&gt;">Hello</b>]]
        [[<b world="&lt;/iframe&gt;" zone="&lt;script&gt;">Hello</b>]]
      }, sanitize_html [[<b world>Hello</b>]]

    it "it extracts attributes from tag for injection", =>
      local attributes
      whitelist.add_attributes.a = {
        rel: (attrs) ->
          attributes = attrs
      }

      out = sanitize_html [[
        <a onclick="alert('hello')" title="good link" href="ftp://example.com" HREF="http://leafo.net">heres a link</a>
      ]]

      assert.same {
        {"onclick", "alert('hello')"}
        {"title", "good link"}
        {"href", "ftp://example.com"}
        {"HREF", "http://leafo.net"}

        onclick: "alert('hello')"
        title: "good link"
        href: "http://leafo.net"
      }, attributes

    it "it extracts attributes for multiple tags", =>
      attributes = {}
      whitelist.add_attributes.a = {
        rel: (attrs) ->
          table.insert attributes, attrs
      }

      out = sanitize_html [[
        <a href="http://leafo.net">test</a>
        <a href="http://itch.io">test</a>
      ]]

      assert.same {
        {
          {"href", "http://leafo.net"}
          href: "http://leafo.net"
        }
        {
          {"href", "http://itch.io"}
          href: "http://itch.io"
        }
      }, attributes


    it "fails if invalid attribute name is used", ->
      whitelist.add_attributes.a = {
        "<script>": "hello"
      }

      assert.has_error(
        ->
          sanitize_html [[
            <a href="http://leafo.net">test</a>
          ]]
        "Attribute name contains invalid characters"
      )


