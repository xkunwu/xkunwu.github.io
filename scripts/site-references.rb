require "addressable/uri"
require "nokogiri"
require "set"

class SiteReferences
  Diagnostic = Data.define(:page, :reference, :reason)
  Failure = Data.define(:page, :error)
  Result = Data.define(:diagnostics, :failures)
  AnchorIndex = Data.define(:ids, :reveal)

  HTML_EXTENSIONS = %w[.html .htm].freeze
  HTTP_SCHEMES = %w[http https].freeze
  OTHER_SCHEME = /\A(?!https?:)[a-z][a-z0-9+.-]*:/i
  READ_ERRORS = [SystemCallError, IOError, Nokogiri::XML::SyntaxError].freeze
  REFERENCE_ATTRIBUTES = {
    "a[href], area[href], link[href]" => "href",
    "[src]" => "src",
    "video[poster]" => "poster",
    "object[data]" => "data"
  }.freeze

  def initialize(directory, site_url)
    @directory = File.realpath(directory)
    @site_url = Addressable::URI.parse(site_url)
  end

  def scan
    diagnostics = []
    @read_failures = {}
    @anchors = {}
    Dir.glob("**/*", File::FNM_DOTMATCH, base: @directory).each do |page|
      next unless html?(page)

      file = File.join(@directory, page)

      begin
        next unless generated_file?(file)

        diagnostics.concat(scan_page(page, file))
      rescue *READ_ERRORS => error
        record_read_failure(file, error)
      end
    end
    Result.new(diagnostics, @read_failures.values)
  end

  private

  def scan_page(page, file)
    document = read_html(file)
    return [] unless document

    @anchors[file] ||= index_anchors(document)
    base_url = reference_base(document, page_url(page))
    seen = Set.new
    diagnostics = []
    REFERENCE_ATTRIBUTES.each do |selector, attribute|
      document.css(selector).each do |element|
        reference = element[attribute]
        url = reference.strip
        next if url.empty? || OTHER_SCHEME.match?(url) || !seen.add?(reference)

        reason = reference_issue(base_url, url)
        diagnostics << Diagnostic.new(page, reference, reason) if reason
      end
    end
    diagnostics
  end

  def page_url(page)
    public_path = File.basename(page) == "index.html" ? page.delete_suffix("index.html") : page
    encoded_path = public_path.split("/", -1).map do |segment|
      Addressable::URI.encode_component(segment, Addressable::URI::CharacterClasses::PCHAR)
    end.join("/")
    @site_url.join("/#{encoded_path}")
  end

  def reference_base(document, page_url)
    document.css("base[href]").each do |element|
      begin
        candidate = page_url.join(element["href"].strip)
        next unless HTTP_SCHEMES.include?(candidate.scheme&.downcase) && candidate.host

        decode_url_part(candidate.path)
        return candidate
      rescue Addressable::URI::InvalidURIError, ArgumentError
        next
      end
    end
    page_url
  end

  def reference_issue(base_url, reference)
    target = base_url.join(reference)
    return unless HTTP_SCHEMES.include?(target.scheme&.downcase) && target.host&.casecmp?(@site_url.host)

    path = decode_url_part(target.path)
    file = published_file(path.empty? ? "/" : path)
    return "missing or empty target file" unless generated_file?(file) && !File.zero?(file)

    fragment = target.fragment
    return if fragment.nil? || fragment.empty? || !html?(file)

    anchors = anchors_for(file)
    return if !anchors || (anchors.reveal && fragment.start_with?("/"))

    anchor = decode_url_part(fragment.partition(":~:").first)
    return if anchor.empty? || anchor.casecmp?("top") || anchors.ids.include?(anchor)

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
    file = File.join(@directory, relative_path)
    index = File.join(file, "index.html")
    return index if path.end_with?("/")
    return file if File.file?(file)
    return index if File.directory?(file)
    return "#{file}.html" if File.extname(file).empty?

    file
  end

  def generated_file?(file)
    File.file?(file) && File.realpath(file).start_with?("#{@directory}/")
  end

  def index_anchors(document)
    ids = Set.new
    document.css("[id], a[name]").each do |element|
      ids.add(element["id"]) if element["id"]
      ids.add(element["name"]) if element.name == "a" && element["name"]
    end
    AnchorIndex.new(ids, !document.at_css(".reveal > .slides").nil?)
  end

  def anchors_for(file)
    @anchors[file] ||= begin
      document = read_html(file)
      index_anchors(document) if document
    end
  end

  def read_html(file)
    return if @read_failures.key?(file)

    # Some published schedules embed images larger than libxml2's default buffer.
    document = Nokogiri::HTML(File.read(file, encoding: "UTF-8")) { |options| options.huge }
    fatal_error = document.errors.find(&:fatal?)
    raise fatal_error if fatal_error

    document
  rescue *READ_ERRORS => error
    record_read_failure(file, error)
    nil
  end

  def record_read_failure(file, error)
    page = file.delete_prefix("#{@directory}/")
    @read_failures[file] ||= Failure.new(page, error)
  end

  def html?(file)
    HTML_EXTENSIONS.include?(File.extname(file).downcase)
  end
end
