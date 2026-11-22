require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "site-references"

class SiteReferencesTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_finds_direct_references_in_all_generated_pages
    write("index.html", <<~HTML)
      <link href="missing.css" rel="stylesheet">
      <a href="missing.html">details</a>
      <area href="missing.html">
      <area href="missing-map.html">
    HTML
    write("teach/Archived/Spring.html", <<~HTML)
      <a href="/missing.html">notes</a>
      <video src="missing.mp4" poster="missing.png"></video>
    HTML
    write("teach/Archived/slides.htm", <<~HTML)
      <object data="missing.pdf"></object>
      <img src="missing.jpg">
    HTML

    result = scan
    assert_equal [
      ["index.html", "missing.css"],
      ["index.html", "missing.html"],
      ["index.html", "missing-map.html"],
      ["teach/Archived/Spring.html", "/missing.html"],
      ["teach/Archived/Spring.html", "missing.mp4"],
      ["teach/Archived/Spring.html", "missing.png"],
      ["teach/Archived/slides.htm", "missing.jpg"],
      ["teach/Archived/slides.htm", "missing.pdf"]
    ].sort, result.diagnostics.map { |issue| [issue.page, issue.reference] }.sort
    assert_empty result.failures
  end

  def test_resolves_local_urls_against_the_first_valid_base
    write("docs/index.html", <<~HTML)
      <base href="mailto:unusable@example.test">
      <base href="../lessons/">
      <base href="/ignored/">
      <a href="week%201?download=yes#named">named anchor</a>
      <a href="/lessons/">directory index</a>
      <a href="https://EXAMPLE.test/download.pdf#page=3">PDF</a>
      <a href="/empty.pdf">empty file</a>
      <a href="bad%escape.html">invalid percent escape</a>
      <a href="/">home</a>
    HTML
    write("lessons/week 1.html", '<a name="named"></a>')
    write("lessons/index.html", "<p>Lessons</p>")
    write("download.pdf", "PDF")
    write("empty.pdf", "")
    write("index.html", "<p>Home</p>")

    assert_equal [
      ["bad%escape.html", "invalid URL"],
      ["/empty.pdf", "missing or empty target file"]
    ].sort, diagnostics.map { |issue| [issue.reference, issue.reason] }.sort
  end

  def test_skips_external_references_and_non_http_schemes
    write("docs/index.html", <<~HTML)
      <base href="https://elsewhere.test/lessons/">
      <a href="not-local.html">external relative link</a>
      <a href="//elsewhere.test/not-local.html">external protocol-relative link</a>
      <a href="mailto:someone@example.test">email</a>
      <img src="data:image/png;base64,example">
      <img data-src="outside-the-scan.jpg">
      <a href="//example.test/missing.pdf">local protocol-relative link</a>
    HTML

    assert_equal ["//example.test/missing.pdf"], diagnostics.map(&:reference)
  end

  def test_checks_references_after_large_embedded_slide_assets
    embedded_image = "data:image/png;base64,#{'A' * 11_000_000}"
    write("slides.html", <<~HTML)
      <img src="#{embedded_image}">
      <a href="missing-handout.pdf">handout</a>
    HTML

    result = scan
    assert_empty result.failures
    assert_equal ["missing-handout.pdf"], result.diagnostics.map(&:reference)
  end

  def test_skips_reveal_routes_and_checks_ordinary_fragments
    write("slide.html", <<~HTML)
      <div class="reveal"><div class="slides">
        <section id="lesson one">
          <a href="#/fn1">Reveal footnote</a>
          <a href="#lesson%20one">native anchor</a>
          <a href="#missing">missing native anchor</a>
        </section>
      </div></div>
    HTML
    write("index.html", <<~HTML)
      <a href="slide.html#/2/1">Reveal route from another page</a>
      <a href="missing.html#/2/1">missing deck</a>
      <a href="#/fn1">ordinary page with a slash fragment</a>
      <a href="#target:~:text=example">text fragment</a>
      <a href="#top">top</a>
      <div id="target">example</div>
    HTML

    assert_equal [
      ["index.html", "missing.html#/2/1", "missing or empty target file"],
      ["index.html", "#/fn1", 'missing HTML anchor "/fn1"'],
      ["slide.html", "#missing", 'missing HTML anchor "missing"']
    ].sort, diagnostics.map { |issue| [issue.page, issue.reference, issue.reason] }.sort
  end

  def test_continues_after_a_page_cannot_be_read
    write("blocked.html", "<p>Unreadable</p>")
    write("index.html", <<~HTML)
      <a href="missing-first.html">broken before</a>
      <a href="blocked.html#anchor">unreadable target</a>
      <a href="missing-last.html">broken after</a>
    HTML
    blocked = File.join(@directory, "blocked.html")
    File.chmod(0, blocked)
    skip "current user can read files without read permissions" if File.readable?(blocked)

    result = scan
    assert_equal ["blocked.html"], result.failures.map(&:page)
    assert_equal %w[missing-first.html missing-last.html], result.diagnostics.map(&:reference)
  end

  private

  def write(path, content)
    file = File.join(@directory, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
  end

  def scan
    SiteReferences.new(@directory, "https://example.test").scan
  end

  def diagnostics
    scan.diagnostics
  end
end
