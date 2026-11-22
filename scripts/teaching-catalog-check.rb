require "json"
require "nokogiri"

class TeachingCatalogCheck
  Diagnostic = Data.define(:source, :message, :output_path)
  Failure = Data.define(:source, :error)
  Result = Data.define(:diagnostics, :failures)

  DATA_SOURCE = "_data/teaching.yml"
  CATALOG_PATH = "teach/index.html"
  CATALOG_SOURCE = "teach/teach.md"
  REDIRECT_LAYOUT = "_layouts/course-redirect.html"

  def initialize(directory, catalog)
    @directory = directory
    @catalog = catalog
  end

  def scan
    @diagnostics = []
    @failures = []
    inspect_source(DATA_SOURCE) do
      courses = @catalog.fetch("current") + @catalog.fetch("archive")
      rows = inspect_source(CATALOG_SOURCE) do
        read_page(CATALOG_PATH, CATALOG_SOURCE)&.css(".pub_row .pub_txt")
      end
      if rows
        check(rows.size == courses.size, DATA_SOURCE, "teaching catalog should show #{courses.size} course rows")
      end

      courses.each_with_index do |course, index|
        inspect_source(DATA_SOURCE) { check_course(course, rows, index) }
      end
    end
    Result.new(@diagnostics, @failures)
  end

  private

  def check(condition, source, message)
    @diagnostics << Diagnostic.new(source, message, nil) unless condition
  end

  def inspect_source(source)
    yield
  rescue StandardError => error
    @failures << Failure.new(source, error)
    nil
  end

  def require_output(path, source)
    file = File.join(@directory, path)
    return file if File.file?(file) && !File.zero?(file)

    @diagnostics << Diagnostic.new(source, "missing or empty #{file}", file)
    nil
  end

  def read_page(path, source)
    file = require_output(path, source)
    Nokogiri::HTML(File.read(file, encoding: "UTF-8")) if file
  end

  def check_course(course, rows, index)
    directory = course.fetch("directory")
    terms = course.fetch("terms")
    check(terms.any?, DATA_SOURCE, "#{directory} should have a default term")
    return if terms.empty?

    expected_links = terms.map { |term| ["#{directory}/#{term.fetch('file')}", term.fetch("label")] }
    if rows
      row = rows[index]
      links = row&.css("links a")&.map { |link| [link["href"], link.text.strip] }
      check(row&.at_css("title")&.text == course.fetch("title") && links == expected_links,
            DATA_SOURCE, "teaching catalog should show #{directory} with its terms in order")
    end
    expected_links.each do |path, _|
      require_output("teach/#{path}", DATA_SOURCE)
    end

    path = "teach/#{directory}/index.html"
    inspect_source(path) { check_course_redirect(path, terms.first) }
  end

  def check_course_redirect(path, default_term)
    page = read_page(path, path)
    return unless page

    target = default_term.fetch("file")
    refresh = page.at_css('meta[http-equiv="refresh"]')&.[]("content")
    check(refresh == "0; url=#{target}", REDIRECT_LAYOUT, "#{path} should refresh to #{target}")

    script = page.css("script").map(&:text).join("\n")
    quoted_target = script[/window\.location\.href\s*=\s*("(?:[^"\\]|\\.)*")\s*;/, 1]
    script_target = begin
      JSON.parse(quoted_target) if quoted_target
    rescue JSON::ParserError
      nil
    end
    check(script_target == target, REDIRECT_LAYOUT, "#{path} should navigate to #{target}")

    fallback = page.at_css("body a")
    check(fallback && fallback["href"] == target && fallback.text.strip == default_term.fetch("label"),
          REDIRECT_LAYOUT, "#{path} should link to #{target} as a fallback")
  end
end
