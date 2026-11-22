require "fileutils"
require "jekyll"
require "minitest/autorun"
require "nokogiri"
require "tmpdir"
require "uri"
require "yaml"
require_relative "teaching-catalog-check"

class TeachingCatalogCheckTest < Minitest::Test
  FIXTURE_FILES = %w[teach/teach.md _includes/teaching-courses.html _layouts/course-redirect.html].freeze

  def setup
    @source = File.realpath(Dir.mktmpdir)
    @output = File.join(@source, "_site")
    FIXTURE_FILES.each do |path|
      destination = File.join(@source, path)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(File.expand_path("../#{path}", __dir__), destination)
    end
    write("_data/teaching.yml", <<~YAML)
      current:
        - directory: Algorithms
          title: Algorithms
          img: Algorithms/teaser.png
          terms:
            - file: A2025H.html
              label: 2025 Autumn
            - file: A2024H.html
              label: 2024 Autumn
      archive:
        - directory: Networking/Tutorial
          title: Networking tutorial
          img: Networking/Tutorial/teaser.png
          terms:
            - file: T2024F.html
              label: 2024 Spring
    YAML
    write("teach/Algorithms/index.html", course_entry("Algorithms"))
    write("teach/Networking/Tutorial/index.html", course_entry("Networking/Tutorial"))
    write("teach/Algorithms/A2025H.html", "<h1>Algorithms 2025 Autumn</h1>")
    write("teach/Algorithms/A2024H.html", "<h1>Algorithms 2024 Autumn</h1>")
    write("teach/Networking/Tutorial/T2024F.html", "<h1>Tutorial 2024 Spring</h1>")
    @catalog = YAML.safe_load_file(File.join(@source, "_data/teaching.yml"))
  end

  def teardown
    FileUtils.remove_entry(@source)
  end

  def test_adding_a_term_changes_the_default_and_preserves_historical_links
    build

    historical_terms = [
      ["Algorithms/A2025H.html", "2025 Autumn", "Algorithms 2025 Autumn"],
      ["Algorithms/A2024H.html", "2024 Autumn", "Algorithms 2024 Autumn"]
    ]
    tutorial = ["Networking tutorial", [
      ["Networking/Tutorial/T2024F.html", "2024 Spring", "Tutorial 2024 Spring"]
    ]]
    assert_catalog [["Algorithms", historical_terms], tutorial]
    assert_redirect "teach/Algorithms/index.html", "A2025H.html", "2025 Autumn"
    assert_redirect "teach/Networking/Tutorial/index.html", "T2024F.html", "2024 Spring"
    assert_clean_scan

    @catalog.fetch("current").first.fetch("terms").unshift("file" => "A2026H.html", "label" => "2026 Autumn")
    write("_data/teaching.yml", YAML.dump(@catalog))
    write("teach/Algorithms/A2026H.html", "<h1>Algorithms 2026 Autumn</h1>")
    build

    new_term = ["Algorithms/A2026H.html", "2026 Autumn", "Algorithms 2026 Autumn"]
    assert_catalog [["Algorithms", [new_term, *historical_terms]], tutorial]
    assert_redirect "teach/Algorithms/index.html", "A2026H.html", "2026 Autumn"
    assert_clean_scan
  end

  def test_reports_a_missing_historical_schedule_and_an_incorrect_fallback
    build
    schedule = File.join(@output, "teach/Algorithms/A2024H.html")
    File.delete(schedule)
    break_tutorial_fallback

    result = scan
    assert_equal [
      ["_data/teaching.yml", "missing or empty #{schedule}"],
      ["_layouts/course-redirect.html", "teach/Networking/Tutorial/index.html should link to T2024F.html as a fallback"]
    ], result.diagnostics.map { |issue| [issue.source, issue.message] }
    assert_empty result.failures
  end

  def test_continues_checking_after_a_course_fails_validation
    build
    @catalog.fetch("current").first.delete("terms")
    break_tutorial_fallback

    result = scan
    assert_equal ["teach/Networking/Tutorial/index.html should link to T2024F.html as a fallback"],
                 result.diagnostics.map(&:message)
    assert_equal [["_data/teaching.yml", KeyError]], result.failures.map { |failure| [failure.source, failure.error.class] }
  end

  private

  def write(path, content)
    file = File.join(@source, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
  end

  def course_entry(directory)
    <<~HTML
      ---
      layout: course-redirect
      course: #{directory}
      ---
    HTML
  end

  def build
    Jekyll::Site.new(Jekyll.configuration(
      "source" => @source, "destination" => @output, "safe" => true, "quiet" => true
    )).process
  end

  def generated_html(path)
    Nokogiri::HTML(File.read(File.join(@output, path), encoding: "UTF-8"))
  end

  def break_tutorial_fallback
    path = "teach/Networking/Tutorial/index.html"
    page = generated_html(path)
    page.at_css("body a")["href"] = "wrong.html"
    File.write(File.join(@output, path), page.to_html)
  end

  def assert_catalog(expected)
    rows = generated_html("teach/index.html").css(".pub_row .pub_txt")
    actual = rows.map do |row|
      terms = row.css("links a").map do |link|
        href = link["href"]
        path = URI.join("https://example.test/teach/", href).path.delete_prefix("/")
        [href, link.text, generated_html(path).at_css("h1")&.text]
      end
      [row.at_css("title")&.text, terms]
    end
    assert_equal expected, actual
  end

  def assert_redirect(path, target, label)
    page = generated_html(path)
    assert_equal "0; url=#{target}", page.at_css('meta[http-equiv="refresh"]')&.[]("content")
    assert_equal "window.location.href = \"#{target}\";", page.at_css("script")&.text&.strip
    fallback = page.at_css("body a")
    assert_equal [target, label], [fallback&.[]("href"), fallback&.text]
  end

  def scan
    TeachingCatalogCheck.new(@output, @catalog).scan
  end

  def assert_clean_scan
    result = scan
    assert_empty result.diagnostics
    assert_empty result.failures
  end
end
