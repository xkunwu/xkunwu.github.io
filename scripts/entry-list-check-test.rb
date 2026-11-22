require "fileutils"
require "jekyll"
require "minitest/autorun"
require "nokogiri"
require "tmpdir"
require "yaml"
require_relative "entry-list-check"

class EntryListCheckTest < Minitest::Test
  FIXTURE_FILES = %w[research/research.md projects/projects.md _includes/entry-groups.html].freeze
  SITE_URL = Addressable::URI.parse("https://example.test")

  def setup
    @source = File.realpath(Dir.mktmpdir)
    @output = File.join(@source, "_site")
    FIXTURE_FILES.each do |path|
      write(path, File.read(File.expand_path("../#{path}", __dir__)))
    end
    write("_layouts/list.html", <<~HTML)
      ---
      ---
      <section class="page__content">{{ content }}</section>
    HTML
    @research = [{"entries" => [{
      "title" => 'Research & "3D" <models>',
      "image" => '/research/one.png?a=1&b="two"',
      "venue" => {"label" => 'Conference <A> & "B"', "url" => "https://venue.test/?a=1&b=2"},
      "links" => [
        {"label" => "Paper & notes", "url" => "/research/paper?a=1&b=2"},
        {"label" => "Details", "url" => "#details"}
      ]
    }]}]
    @projects = [
      {"entries" => [project("First project"), project("Second project")]},
      {"title" => "Projects <A> & B", "id" => 'group-a&"b"', "entries" => [project("Third project")]},
      {"title" => "Other projects", "entries" => [project("Fourth project")]}
    ]
  end

  def teardown
    FileUtils.remove_entry(@source)
  end

  def test_generated_research_and_projects_match_their_yaml
    build

    assert_empty scan("research")
    assert_empty scan("projects")
  end

  def test_identifies_a_missing_entry_and_wrong_group_structure
    build
    edit_page("projects") do |page|
      page.css(".page__content > article").last.remove
      sections = page.css(".pub_group")
      sections.first.add_previous_sibling(sections.last)
    end

    warnings = scan("projects")
    assert_warning warnings, /group 1, entry 2 \("Second project"\).*should render as <article>/
    assert_warning warnings, /group 2 .*heading text.*"Projects <A> & B"/
  end

  def test_identifies_entries_out_of_order_and_changed_headings_and_anchor
    build
    edit_page("projects") do |page|
      first, second = page.css(".page__content > article")
      first.add_previous_sibling(second)
      second.at_css("h2").name = "h3"
      group = page.at_css(".pub_group")
      group.at_css("h2")["id"] = "wrong"
      group.at_css("article h3").name = "h2"
    end

    warnings = scan("projects")
    assert_warning warnings, /group 1, entry 1 .*heading text.*"First project".*"Second project"/
    assert_warning warnings, /group 1, entry 1 .*heading tag.*"h2".*"h3"/
    assert_warning warnings, /group 2 .*anchor.*"wrong"/
    assert_warning warnings, /group 2 .*entry 1 .*heading tag.*"h3".*"h2"/
  end

  def test_identifies_an_extra_entry_nested_outside_its_group
    build
    edit_page("research") do |page|
      page.at_css(".page__content").add_child('<div><article><h2>Stray entry</h2></article></div>')
    end

    assert_warning scan("research"), /entry "Stray entry".*directly under/
  end

  def test_identifies_an_extra_entry_before_a_correct_section
    build
    edit_page("projects") do |page|
      page.at_css(".pub_group").add_previous_sibling('<article><h2>Stray entry</h2></article>')
    end

    assert_equal ['group 2 has unexpected entry "Stray entry" before its section'], scan("projects")
  end

  def test_identifies_missing_and_reordered_links_and_a_rewritten_venue_url
    build
    edit_page("research") do |page|
      venue, paper, details = page.css("article a")
      venue["href"] = "https://venue.test/another-page"
      paper.add_previous_sibling(details)
    end

    warnings = scan("research")
    assert_warning warnings, /group 1, entry 1 .*venue .*href.*https:\/\/venue.test\/another-page/
    assert_warning warnings, /group 1, entry 1 .*link .*\("Paper & notes"\) label.*"Details"/

    edit_page("research") { |page| page.css("article a").last.remove }
    assert_warning scan("research"), /group 1, entry 1 .*link .*\("Details"\) is missing/
  end

  def test_identifies_missing_and_rewritten_thumbnails
    build
    edit_page("projects") do |page|
      first, second = page.css("article img")
      first.remove
      second["src"] = "/projects/another-thumbnail.png"
    end

    warnings = scan("projects")
    assert_warning warnings, /group 1, entry 1 .*thumbnail src.*found nil/
    assert_warning warnings, %r{group 1, entry 2 .*thumbnail src.*found "/projects/another-thumbnail.png"}
  end

  def test_warns_when_the_thumbnail_is_missing_from_yaml_and_the_page
    @research.first.fetch("entries").first["image"] = nil
    build
    edit_page("research") { |page| page.at_css("article img").remove }

    assert_warning scan("research"), /group 1, entry 1 .*thumbnail src.*missing or empty/
  end

  def test_warns_when_an_empty_list_matches_its_yaml
    @research.clear
    build

    assert_equal ["entry list should display at least one entry"], scan("research")
  end

  def test_warns_for_page_relative_paths_and_links_to_the_site_host
    entry = @research.first.fetch("entries").first
    entry["image"] = "images/thumbnail.png"
    entry.fetch("venue")["url"] = "http://EXAMPLE.test/venue"
    entry["links"] += [
      {"label" => "Relative", "url" => "../paper"},
      {"label" => "Same host", "url" => "//example.test/paper"},
      {"label" => "External", "url" => "//external.test/paper"}
    ]
    build

    warnings = scan("research")
    assert_equal 4, warnings.size, warnings.join("\n")
    assert_warning warnings, /group 1, entry 1 .*thumbnail src.*page-relative/
    assert_warning warnings, /group 1, entry 1 .*venue .*href.*site's host/
    assert_warning warnings, /group 1, entry 1 .*\("Relative"\) href.*page-relative/
    assert_warning warnings, /group 1, entry 1 .*\("Same host"\) href.*site's host/
  end

  private

  def project(title)
    {"title" => title, "image" => "/projects/thumbnail.png",
     "links" => [{"label" => "Code", "url" => "https://code.test/project"}]}
  end

  def write(path, content)
    file = File.join(@source, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
  end

  def build
    write("_data/research.yml", YAML.dump("groups" => @research))
    write("_data/projects.yml", YAML.dump("groups" => @projects))
    Jekyll::Site.new(Jekyll.configuration(
      "source" => @source, "destination" => @output, "safe" => true, "quiet" => true,
      "defaults" => [{"scope" => {"path" => ""}, "values" => {"layout" => "list"}}]
    )).process
  end

  def scan(section)
    groups = YAML.safe_load_file(File.join(@source, "_data/#{section}.yml")).fetch("groups")
    page = read_page(section)
    EntryListCheck.new(groups, page, SITE_URL).scan
  end

  def read_page(section)
    Nokogiri::HTML(File.read(File.join(@output, section, "index.html"), encoding: "UTF-8"))
  end

  def edit_page(section)
    page = read_page(section)
    yield page
    File.write(File.join(@output, section, "index.html"), page.to_html)
  end

  def assert_warning(warnings, pattern)
    assert warnings.any? { |warning| pattern.match?(warning) }, warnings.join("\n")
  end
end
