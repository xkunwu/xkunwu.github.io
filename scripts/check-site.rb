require "addressable/uri"
require "json"
require "nokogiri"
require "yaml"

class SiteCheck
  PAGES = {
    "index.html" => ["pages/home.md", "Welcome to WU Xiaokun’s homepage!"],
    "teach/index.html" => ["teach/teach.md", "Teach"],
    "research/index.html" => ["research/research.md", "Research"],
    "projects/index.html" => ["projects/projects.md", "Projects"],
    "projects/hand-track/hand-track.html" => ["projects/hand-track/hand-track.md", "Hand detection and tracking"]
  }.freeze
  TEACHING = "_data/teaching.yml"
  ENTRY_LINKS = ".page__content .pub_row a[href]"
  ENTRY_THUMBNAILS = ".page__content .pub_img img, .page__content .pub_img video"

  def initialize
    @findings = {}
    @missing_outputs = {}
    @documents = {}
  end

  def run
    PAGES.each do |path, (source, title)|
      inspect_source(source) { check_page(path, source, title) }
    end
    inspect_source("assets/css/main.scss") { check_styles }
    inspect_source("COPYRIGHT.txt") { require_output("COPYRIGHT.txt", "COPYRIGHT.txt") }
    inspect_source("research/research.md") { check_research }
    inspect_source("projects/projects.md") { check_projects }
    inspect_source(PAGES.fetch("projects/hand-track/hand-track.html").first) { check_hand_track }
    inspect_source("_config.yml") { check_exclusions }
    inspect_source("_config.yml") { @site_url = read_site_url }
    inspect_source(TEACHING) { check_teaching }

    if @site_url
      inspect_source(TEACHING) do
        check_references("teach/index.html", TEACHING, ENTRY_THUMBNAILS, "src")
      end
      %w[research projects].each do |section|
        source = "_data/#{section}.yml"
        inspect_source(source) do
          check_references("#{section}/index.html", source, ENTRY_LINKS, "href")
          check_references("#{section}/index.html", source, ENTRY_THUMBNAILS, "src")
        end
      end
    end
  rescue StandardError => error
    record_incomplete("scripts/check-site.rb", error)
  ensure
    report
  end

  private

  def check(condition, source, message)
    return if condition

    (@findings[source] ||= []) << message
  end

  def inspect_source(source)
    yield
  rescue StandardError => error
    record_incomplete(source, error)
  end

  def record_incomplete(source, error)
    @incomplete = true
    check(false, source, "Check incomplete (#{error.class}): #{error.message.inspect}")
    nil
  end

  def output_file?(path)
    File.file?(path) && !File.zero?(path)
  end

  def require_output(path, source)
    file = File.join("_site", path)
    return file if output_file?(file)

    unless @missing_outputs[file]
      check(false, source, "missing or empty #{file}")
      @missing_outputs[file] = true
    end
    nil
  end

  def document(path)
    @documents[path] ||= Nokogiri::HTML(File.read(path, encoding: "UTF-8"))
  end

  def page_document(path, source)
    file = require_output(path, source)
    document(file) if file
  end

  def check_page(path, source, title)
    page = page_document(path, source)
    return unless page

    check(page.at_css("#page-title")&.text&.strip == title, source, "#{path} should show #{title}")
    check(page.at_css('link[rel="stylesheet"][href="/assets/css/main.css"]'), source, "#{path} should load the theme CSS")
    copyright = page.at_css('.page__footer-copyright a[href="/COPYRIGHT.txt"]')
    check(copyright&.text&.match?(/\A2018 - \d{4} WU Xiaokun\.\z/), source, "#{path} should show the copyright link")
  end

  def check_styles
    source = "assets/css/main.scss"
    file = require_output("assets/css/main.css", source)
    return unless file

    css = File.read(file, encoding: "UTF-8")
    %w[.masthead .pub_row].each do |selector|
      check(css.include?(selector), source, "theme CSS should include #{selector}")
    end
  end

  def check_research
    path = "research/index.html"
    source = PAGES.fetch(path).first
    page = page_document(path, source)
    return unless page

    content = page.at_css(".page__content")
    check(content, source, "Research should show its page content")
    return unless content

    entries = content.css("article")
    check(entries.any? && entries.all? { |entry| entry.parent == content && entry.at_css("h2") },
          "_data/research.yml", "Research should show its entries directly under the page content with h2 titles")
  end

  def check_projects
    path = "projects/index.html"
    page = page_document(path, PAGES.fetch(path).first)
    return unless page

    source = "_data/projects.yml"
    entries = page.css(".page__content > article")
    check(entries.any? && entries.all? { |entry| entry.at_css("h2") },
          source, "Projects should show entries from the untitled group directly under the page content with h2 titles")
    bath_heading = page.at_css(".page__content > section > h2#at-camera-group-of-bath")
    check(bath_heading&.text == "At CAMERA group of Bath", source, "Projects should show the Bath group heading and anchor")
    return unless bath_heading

    bath_entries = bath_heading.parent.xpath("./article")
    check(bath_entries.any? && bath_entries.all? { |entry| entry.at_css("h3") },
          source, "The Bath group should show its entries with h3 titles")
    check(bath_heading.parent.at_css('article a[href="hand-track/hand-track"]')&.text == "Webpage",
          source, "The Bath group should link to Hand Track")
  end

  def check_hand_track
    path = "projects/hand-track/hand-track.html"
    source = PAGES.fetch(path).first
    page = page_document(path, source)
    return unless page

    %w[assumptions faq].each do |heading|
      check(page.at_css(".toc__menu a[href='##{heading}']") && page.at_css("##{heading}"),
            source, "Hand Track should link to ##{heading} from its table of contents")
    end
  end

  def check_exclusions
    %w[Gemfile.lock scripts/check-site.rb vendor/bundle].each do |path|
      check(!File.exist?(File.join("_site", path)), "_config.yml", "#{path} should be excluded from the site")
    end
  end

  def check_teaching
    catalog = YAML.safe_load_file(TEACHING)
    courses = catalog.fetch("current") + catalog.fetch("archive")
    page = page_document("teach/index.html", "teach/teach.md")
    rows = page&.css(".pub_row .pub_txt")
    check(rows.size == courses.size, TEACHING, "teaching catalog should show #{courses.size} course rows") if rows

    term_paths = courses.each_with_index.flat_map do |course, index|
      inspect_source(TEACHING) do
        check_course(course, rows&.[](index), check_row: !!rows)
      end || []
    end
    return unless @site_url

    term_paths.uniq.each do |path|
      inspect_source(path) { check_references(path, path, "body a[href]", "href") }
    end
  end

  def check_course(course, row, check_row:)
    directory = course.fetch("directory")
    terms = course.fetch("terms")
    check(terms.any?, TEACHING, "#{directory} should have a default term")
    return if terms.empty?

    expected_links = terms.map { |term| ["#{directory}/#{term.fetch('file')}", term.fetch("label")] }
    if check_row
      links = row&.css("links a")&.map { |link| [link["href"], link.text.strip] }
      check(row&.at_css("title")&.text == course.fetch("title") && links == expected_links,
            TEACHING, "teaching catalog should show #{directory} with its terms in order")
    end
    term_paths = expected_links.filter_map do |path, _|
      term_path = "teach/#{path}"
      term_path if require_output(term_path, TEACHING)
    end
    check_course_redirect(directory, terms.first)
    term_paths
  end

  def check_course_redirect(directory, default_term)
    path = "teach/#{directory}/index.html"
    source = "_layouts/course-redirect.html"
    page = page_document(path, path)
    return unless page

    target = default_term.fetch("file")
    refresh = page.at_css('meta[http-equiv="refresh"]')&.[]("content")
    check(refresh == "0; url=#{target}", source, "#{path} should refresh to #{target}")

    script = page.css("script").map(&:text).join("\n")
    quoted_target = script[/window\.location\.href\s*=\s*("(?:[^"\\]|\\.)*")\s*;/, 1]
    script_target = begin
      JSON.parse(quoted_target) if quoted_target
    rescue JSON::ParserError
      nil
    end
    check(script_target == target, source, "#{path} should navigate to #{target}")

    fallback = page.at_css("body a")
    check(fallback && fallback["href"] == target && fallback.text.strip == default_term.fetch("label"),
          source, "#{path} should link to #{target} as a fallback")
  end

  def read_site_url
    url = Addressable::URI.parse(YAML.safe_load_file("_config.yml").fetch("url"))
    valid = %w[http https].include?(url.scheme&.downcase) && url.host
    check(valid, "_config.yml", "site URL should be an absolute HTTP(S) URL")
    url if valid
  end

  def check_references(page_path, source, selector, attribute)
    page = page_document(page_path, source)
    return unless page

    public_path = File.basename(page_path) == "index.html" ? page_path.delete_suffix("index.html") : page_path
    page_url = @site_url.join("/#{public_path}")
    references = page.css(selector).map { |node| node[attribute].to_s.strip }.uniq
    references.each do |reference|
      issue = if attribute == "src" && reference.empty?
        "missing thumbnail URL"
      else
        reference_issue(page_url, reference)
      end
      check(false, source, "#{page_path} references #{reference.inspect} (#{issue})") if issue
    end
  end

  def reference_issue(page_url, reference)
    return if reference.empty?

    target = page_url.join(Addressable::URI.parse(reference))
    return unless %w[http https].include?(target.scheme&.downcase) && target.host&.casecmp?(page_url.host)

    path = decode_url_part(target.path)
    file = published_file(path.empty? ? "/" : path)
    return if @missing_outputs[file]

    return "missing or empty target file" unless output_file?(file)

    fragment = target.fragment
    return if fragment.nil? || fragment.empty? || !%w[.html .htm].include?(File.extname(file).downcase)

    anchor = decode_url_part(fragment.partition(":~:").first)
    return if anchor.empty? || anchor.casecmp?("top")

    ids = document(file).css("[id], a[name]")
    return if ids.any? { |node| node["id"] == anchor || (node.name == "a" && node["name"] == anchor) }

    "missing HTML anchor #{anchor.inspect}"
  rescue Addressable::URI::InvalidURIError, ArgumentError
    "invalid URL"
  end

  def decode_url_part(part)
    raise ArgumentError if part.match?(/%(?![0-9a-f]{2})/i)

    decoded = Addressable::URI.unencode(part)
    raise ArgumentError if decoded.include?("\0")

    decoded
  end

  def published_file(path)
    relative_path = File.expand_path(path, "/").delete_prefix("/")
    file = File.join("_site", relative_path)
    index = File.join(file, "index.html")
    return index if path.end_with?("/")
    return file if File.file?(file)
    return index if File.directory?(file)
    return "#{file}.html" if File.extname(file).empty?

    file
  end

  def report
    count = @findings.values.sum { |messages| messages.uniq.size }
    outcome = @incomplete ? "incomplete" : "completed"
    warnings = count.zero? ? "no warnings" : "#{count} warning(s)"
    headline = "Site check #{outcome} with #{warnings}."
    lines = @findings.sort.flat_map do |source, messages|
      [source, *messages.uniq.map { |message| "  - #{message}" }]
    end
    puts headline, *lines

    summary = ENV["GITHUB_STEP_SUMMARY"]
    return if summary.nil? || summary.empty?

    File.open(summary, "a") do |file|
      file.puts "## Site check", "", headline
      unless lines.empty?
        file.puts ""
        lines.each { |line| line.each_line { |part| file.puts "    #{part}" } }
      end
      file.puts ""
    end
  end
end

SiteCheck.new.run
