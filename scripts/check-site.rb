require "addressable/uri"
require "nokogiri"
require "yaml"
require_relative "entry-list-check"
require_relative "site-check-report"
require_relative "site-references"
require_relative "teaching-catalog-check"

class SiteCheck
  PAGES = {
    "index.html" => ["pages/home.md", "Welcome to WU Xiaokun’s homepage!"],
    TeachingCatalogCheck::CATALOG_PATH => [TeachingCatalogCheck::CATALOG_SOURCE, "Teach"],
    "research/index.html" => ["research/research.md", "Research"],
    "projects/index.html" => ["projects/projects.md", "Projects"],
    "projects/hand-track/hand-track.html" => ["projects/hand-track/hand-track.md", "Hand detection and tracking"]
  }.freeze
  TEACHING = TeachingCatalogCheck::DATA_SOURCE
  ENTRY_THUMBNAILS = ".page__content .pub_img img, .page__content .pub_img video"
  SITE_URL_CHECKS = "Site references and host checks for Research and Projects"

  def initialize
    @report = SiteCheckReport.new
    @documents = {}
  end

  def run
    PAGES.each do |path, (source, title)|
      inspect_source(source, "Page structure") { check_page(path, source, title) }
    end
    inspect_source("assets/css/main.scss", "Theme CSS") { check_styles }
    inspect_source("COPYRIGHT.txt", "Copyright file") { require_output("COPYRIGHT.txt", "COPYRIGHT.txt") }
    inspect_source(PAGES.fetch("projects/hand-track/hand-track.html").first, "Hand Track table of contents") { check_hand_track }
    inspect_source("_config.yml", "Site exclusions") { check_exclusions }
    inspect_source(TEACHING, "Teaching catalog") { check_teaching }
    Dir.glob("teach/*/raster/*/index.html").each do |source|
      inspect_source(source, "Image-based slides") { check_raster_slides(source) }
    end

    inspect_source(TEACHING, "Teaching catalog thumbnails") do
      check_thumbnail_urls(TeachingCatalogCheck::CATALOG_PATH, TEACHING)
    end

    site_url = inspect_source("_config.yml", SITE_URL_CHECKS) { read_site_url }
    %w[research projects].each { |section| check_entry_list(section, site_url) }
    inspect_source("scripts/site-references.rb", "Site references") { check_site_references(site_url) } if site_url
  rescue StandardError => error
    record_incomplete("scripts/check-site.rb", "Site checks", error)
  ensure
    @report.write
  end

  private

  def check(condition, source, message)
    @report.warning(source, message) unless condition
  end

  def inspect_source(source, check_name)
    yield
  rescue StandardError => error
    record_incomplete(source, check_name, error)
    nil
  end

  def record_incomplete(source, check_name, error)
    @report.incomplete(source, "#{check_name} (#{error.class}): #{error.message.inspect}")
  end

  def output_file?(path)
    File.file?(path) && !File.zero?(path)
  end

  def require_output(path, source)
    file = File.join("_site", path)
    return file if output_file?(file)

    @report.missing_output(source, file)
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

  def check_entry_list(section, site_url)
    path = "#{section}/index.html"
    source = PAGES.fetch(path).first
    page = inspect_source(source, "#{section.capitalize} list") { page_document(path, source) }
    data_source = "_data/#{section}.yml"
    inspect_source(data_source, "#{section.capitalize} list") do
      groups = YAML.safe_load_file(data_source).fetch("groups")
      if page
        EntryListCheck.new(groups, page, site_url).scan.each do |message|
          @report.warning(data_source, "#{path}: #{message}")
        end
      end
    end
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
    %w[Gemfile.lock scripts vendor/bundle].each do |path|
      check(!File.exist?(File.join("_site", path)), "_config.yml", "#{path} should be excluded from the site")
    end
  end

  def check_teaching
    catalog = YAML.safe_load_file(TEACHING)
    result = TeachingCatalogCheck.new("_site", catalog).scan
    result.diagnostics.each do |issue|
      if issue.output_path
        @report.missing_output(issue.source, issue.output_path)
      else
        @report.warning(issue.source, issue.message)
      end
    end
    result.failures.each { |failure| record_incomplete(failure.source, "Teaching catalog", failure.error) }
  end

  def read_site_url
    value = YAML.safe_load_file("_config.yml").fetch("url")
    url = Addressable::URI.parse(value)
    if url && %w[http https].include?(url.scheme&.downcase) && !url.host.to_s.empty?
      return url
    end

    raise Addressable::URI::InvalidURIError, "site URL should be an absolute HTTP(S) URL"
  end

  def check_raster_slides(source)
    page = page_document(source, source)
    return unless page

    expected = Dir.children(File.dirname(source)).select do |name|
      name.match?(/\A[0-9]{3}\.jpg\z/) && File.file?(File.join(File.dirname(source), name))
    end.sort
    slides = page.css("#slides img").map { |image| image["src"] }
    thumbnails = page.css("#thumbnails img").map { |image| image["src"] }
    check(slides == expected, source, "slide images should match the directory's numbered JPEGs in order")
    check(thumbnails == expected, source, "thumbnails should match the directory's numbered JPEGs in order")
  end

  def check_thumbnail_urls(page_path, source)
    page = page_document(page_path, source)
    return unless page

    missing = page.css(ENTRY_THUMBNAILS).any? { |node| node["src"].to_s.strip.empty? }
    check(!missing, source, "#{page_path} has a missing thumbnail URL")
  end

  def check_site_references(site_url)
    result = SiteReferences.new("_site", site_url).scan
    result.diagnostics.each do |issue|
      @report.warning(issue.page, "#{issue.page} references #{issue.reference.inspect} (#{issue.reason})")
    end
    result.failures.each { |failure| record_incomplete(failure.page, "Site references", failure.error) }
  end
end

SiteCheck.new.run
