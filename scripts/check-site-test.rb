require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class CheckSiteTest < Minitest::Test
  CHECKER = File.join(__dir__, "check-site.rb")
  SUMMARY_HEADER = "## Site check\n\n"
  PAGES = {
    "index.html" => "Welcome to WU Xiaokun’s homepage!",
    "teach/index.html" => "Teach",
    "research/index.html" => "Research",
    "projects/index.html" => "Projects",
    "projects/hand-track/hand-track.html" => "Hand detection and tracking"
  }.freeze

  def setup
    @root = Dir.mktmpdir
    @summary = File.join(@root, "summary.md")
    write("_config.yml", "url: https://example.test\n")
    write("_data/teaching.yml", "current: []\narchive: []\n")
    write("_site/assets/css/main.css", ".masthead {} .pub_row {}")
    write("_site/COPYRIGHT.txt", "Copyright")
    write("_site/preview.png", "image")
    PAGES.each do |path, title|
      content = case path
                when "research/index.html", "projects/index.html"
                  section = File.dirname(path)
                  entry_list(section, title, "/preview.png")
                when "projects/hand-track/hand-track.html"
                  <<~HTML
                    <nav class="toc__menu"><a href="#assumptions">Assumptions</a><a href="#faq">FAQ</a></nav>
                    <h2 id="assumptions">Assumptions</h2><h2 id="faq">FAQ</h2>
                  HTML
                end
      write_page(path, title, content)
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_clean_run_preserves_the_headline
    assert_equal "Site check completed with no warnings.\n", run_check
  end

  def test_valid_unicode_site_url_still_checks_same_host_references
    write("_config.yml", "url: https://example.test/研究\n")
    write("_site/reference.html", '<a href="https://example.test/missing.pdf">PDF</a>')

    assert_equal <<~REPORT, run_check
      Site check completed with 1 warning(s).
      reference.html
        - reference.html references "https://example.test/missing.pdf" (missing or empty target file)
    REPORT
  end

  def test_missing_outputs_are_reported_once_and_broken_links_are_reported_per_page
    File.delete(File.join(@root, "_site/teach/index.html"))
    %w[first second].each do |name|
      write("_site/#{name}.html", '<a href="/missing.pdf">PDF</a><a href="/missing.pdf">Again</a>')
    end

    assert_equal <<~REPORT, run_check
      Site check completed with 3 warning(s).
      first.html
        - first.html references "/missing.pdf" (missing or empty target file)
      second.html
        - second.html references "/missing.pdf" (missing or empty target file)
      teach/teach.md
        - missing or empty _site/teach/index.html
    REPORT
  end

  def test_missing_output_keeps_the_first_reporting_source
    path = "teach/Algorithms/raster/Week1/index.html"
    write(path, "<h1>Slides</h1>")
    write("_data/teaching.yml", <<~YAML)
      current:
        - directory: Algorithms
          title: Algorithms
          terms:
            - file: raster/Week1/index.html
              label: Week 1
      archive: []
    YAML

    report = run_check
    assert_equal 1, report.lines.count { |line| line.strip == "- missing or empty _site/#{path}" }
    assert_includes report, "_data/teaching.yml\n  - missing or empty _site/#{path}\n"
  end

  def test_repeated_incomplete_reason_is_counted_once
    write("_data/teaching.yml", <<~YAML)
      current:
        - title: Algorithms
        - title: Networks
      archive: []
    YAML
    write_page("teach/index.html", "Teach", '<div class="pub_row"><div class="pub_txt"></div></div>' * 2)

    report = run_check
    assert_match(/\ASite check incomplete with no warnings and 1 incomplete reason\(s\)\./, report)
    assert_equal 1, report.scan("Teaching catalog (KeyError)").size
  end

  def test_invalid_url_counts_a_warning_and_an_incomplete_reason_separately
    write("_config.yml", "url: https:///missing-host\n")
    write_page("research/index.html", "Research", entry_list("research", "Research", "preview.png"))
    write("_site/skipped.html", '<a href="/missing.pdf">PDF</a>')

    report = run_check
    assert_match(/\ASite check incomplete with 1 warning\(s\) and 1 incomplete reason\(s\)\./, report)
    assert_match(/_config\.yml\n  - .*site URL should be an absolute HTTP\(S\) URL/, report)
    assert_includes report, "Site references"
    assert_includes report, "Research and Projects"
    assert_match(/_data\/research\.yml\n  - .*is page-relative and should start with \//, report)
    refute_includes report, "missing.pdf"
  end

  def test_malformed_config_still_checks_both_entry_lists
    write("_config.yml", "url: [\n")
    %w[research projects].each do |section|
      title = section.capitalize
      content = entry_list(section, title, "preview.png").sub("<h2>#{title}</h2>", "<h2>Wrong</h2>")
      write_page("#{section}/index.html", title, content)
    end

    report = run_check
    assert_match(/\ASite check incomplete with 4 warning\(s\) and 1 incomplete reason\(s\)\./, report)
    assert_match(/_config\.yml\n  - .*Psych::SyntaxError/, report)
    %w[research projects].each do |section|
      assert_match(/#{section}\/index\.html: .*heading text expected "#{section.capitalize}", found "Wrong"/, report)
      assert_match(/#{section}\/index\.html: .*is page-relative and should start with \//, report)
    end
  end

  def test_unreadable_generated_page_does_not_stop_other_reference_checks
    write("_site/unreadable.html", "<p>Unreadable</p>")
    unreadable = File.join(@root, "_site/unreadable.html")
    File.chmod(0o000, unreadable)
    skip "requires a user subject to file read permissions" if File.readable?(unreadable)

    write("_site/readable.html", '<a href="/missing.pdf">PDF</a>')

    report = run_check
    assert_match(/\ASite check incomplete with 1 warning\(s\) and 1 incomplete reason\(s\)\./, report)
    assert_match(/unreadable\.html\n  - .*Site references.*Errno::EACCES/, report)
    assert_includes report, 'readable.html references "/missing.pdf" (missing or empty target file)'
  end

  def test_unreadable_generated_directory_does_not_stop_other_reference_checks
    write("_site/hidden/index.html", "<p>Unreadable</p>")
    directory = File.join(@root, "_site/hidden")
    File.chmod(0o000, directory)
    skip "requires a user subject to directory read permissions" if File.readable?(directory)

    write("_site/readable.html", '<a href="/missing.pdf">PDF</a>')

    report = run_check
    assert_match(/\ASite check incomplete with 1 warning\(s\) and 1 incomplete reason\(s\)\./, report)
    assert_match(/hidden\n  - .*Site references.*Errno::EACCES/, report)
    assert_includes report, 'readable.html references "/missing.pdf" (missing or empty target file)'
  ensure
    File.chmod(0o700, directory) if directory
  end

  private

  def write(path, content)
    file = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
  end

  def entry_list(section, title, image)
    write("_data/#{section}.yml", YAML.dump("groups" => [
      {"entries" => [{"title" => title, "image" => image}]}
    ]))
    <<~HTML
      <div class="page__content">
        <article><h2>#{title}</h2><div class="pub_img"><img src="#{image}"></div></article>
      </div>
    HTML
  end

  def write_page(path, title, content)
    write("_site/#{path}", <<~HTML)
      <link rel="stylesheet" href="/assets/css/main.css">
      <h1 id="page-title">#{title}</h1>
      #{content}
      <footer class="page__footer-copyright"><a href="/COPYRIGHT.txt">2018 - 2026 WU Xiaokun.</a></footer>
    HTML
  end

  def run_check
    previous_summary = "Previous step\n\n"
    File.write(@summary, previous_summary)
    output, error, status = Open3.capture3(
      {"GITHUB_STEP_SUMMARY" => @summary}, RbConfig.ruby, CHECKER, chdir: @root
    )
    assert status.success?, error
    assert_empty error

    headline, *details = output.lines
    expected_summary = previous_summary + SUMMARY_HEADER + headline + "\n"
    expected_summary += details.map { |line| line.strip.empty? ? line : "    #{line}" }.join
    expected_summary += "\n" unless details.empty?
    assert_equal expected_summary, File.read(@summary)
    output
  end
end
