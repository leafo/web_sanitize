-- Property checks over random input. FUZZ_ITERATIONS and FUZZ_SEED control the
-- run, see `make fuzz`. Failures reproduce only by rerunning the same seed up
-- to the failing iteration on the same Lua interpreter: some properties reuse
-- instances across iterations, and math.random differs between interpreters.

import random_html, random_selector, random_stack_selector, random_tree, render_tree,
  render_tree_edited, tree_edit_callback, random_edit_callback from require "spec.support.random_html"

ITERATIONS = tonumber(os.getenv "FUZZ_ITERATIONS") or 100
SEED = tonumber(os.getenv "FUZZ_SEED") or 1

fuzz = (fn) ->
  for i=1,ITERATIONS
    seed = SEED + i
    math.randomseed seed
    ok, err = pcall fn, i
    unless ok
      interpreter = jit and jit.version or _VERSION
      error "#{err}\nreproduce on #{interpreter} with FUZZ_SEED=#{SEED} FUZZ_ITERATIONS=#{i}", 0

-- every 50th input is long enough to use the sanitizer's chunked parsing
fuzz_html = (i) ->
  random_html i % 50 == 0 and 2000 or 30

no_error = (html, fn, ...) ->
  ok, err = pcall fn, ...
  assert ok, "#{err}\ninput: #{string.format "%q", html}"

describe "fuzz", ->
  import Sanitizer, Extractor from require "web_sanitize.html"
  import scan_html, replace_html from require "web_sanitize.query.scan_html"
  import query_all, match_query from require "web_sanitize.query"
  import parse_query from require "web_sanitize.query.parse_query"

  it "processes malformed input without errors", ->
    processors = {
      Sanitizer!
      Sanitizer strip_tags: true
      Sanitizer strip_comments: true
      Extractor!
      Extractor escape_html: true
      Extractor printable: true
    }

    fuzz (i) ->
      html = fuzz_html i
      for process in *processors
        no_error html, process, html

      for text_nodes in *{false, true}
        no_error html, scan_html, html, (->), :text_nodes
        no_error html, replace_html, html, random_edit_callback, :text_nodes

      no_error html, query_all, html, random_selector!

  it "applies replace_html edits like the tree model", ->
    fuzz ->
      tree = random_tree!
      source = render_tree tree
      out = replace_html source, tree_edit_callback(tree), text_nodes: true
      assert.same render_tree_edited(tree), out, "input: #{source}"

  it "matches selectors the same on the scanner's stack and a plain table", ->
    fuzz (i) ->
      html = fuzz_html i
      queries = [parse_query random_selector! for _=1,4]

      scan_html html, (stack) ->
        plain = [node for node in *stack]
        stack_queries = [parse_query random_stack_selector stack for _=1,2]
        for q in *queries
          assert.same match_query(plain, q), match_query(stack, q), "input: #{html}"

        for q in *stack_queries
          assert.same match_query(plain, q), match_query(stack, q), "input: #{html}"

  it "keeps the scanner's tag index in sync with the stack", ->
    fuzz (i) ->
      html = fuzz_html i
      scan_html html, ((stack) ->
        expected = {}
        for idx, node in ipairs stack
          continue if node.type == "text_node"
          expected[node.tag] or= {}
          table.insert expected[node.tag], idx

        for tag, positions in pairs stack._tag_positions
          assert.same expected[tag] or {}, positions, "input: #{html}"
      ), text_nodes: true

  it "gives the same output from a reused and a fresh instance", ->
    whitelist = require("web_sanitize.whitelist")\clone!
    whitelist.add_attributes.a = {
      rel: (attrs) -> "r:#{attrs.href}"
    }

    configs = {
      { Sanitizer, {} }
      { Sanitizer, { strip_tags: true } }
      { Sanitizer, { strip_comments: true } }
      { Sanitizer, { :whitelist } }
      { Extractor, {} }
      { Extractor, { escape_html: true } }
    }

    reused = [make opts for {make, opts} in *configs]

    fuzz (i) ->
      html = fuzz_html i
      for idx, {make, opts} in ipairs configs
        assert.same make(opts)(html), reused[idx](html), "input: #{html}"

  it "fails a close_follows guarded scan exactly when the unguarded one fails", ->
    import P from require "lpeg"
    import close_follows from require "web_sanitize.patterns"

    fuzz ->
      for {open, close} in *{{"<!--", "-->"}, {"<![CDATA[", "]]>"}}
        pattern = P(open) * (P(1) - P(close))^0 * P(close)
        guard, reset = close_follows open, close
        guarded = guard * pattern

        pieces = {open, close, "x", "-", "]", "<", ">", "!"}
        subject = table.concat [pieces[math.random #pieces] for _=1,math.random 0, 20]

        reset!
        for pos=1,#subject + 1
          assert.same pattern\match(subject, pos), guarded\match(subject, pos), "input: #{subject}"
