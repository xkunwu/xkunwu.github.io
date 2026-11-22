require "addressable/uri"

class EntryListCheck
  HEADINGS = "h1, h2, h3, h4, h5, h6"

  def initialize(groups, page, site_url)
    @groups = groups
    @page = page
    @site_url = site_url
  end

  def scan
    @warnings = []
    content = @page.at_css(".page__content")
    unless content
      @warnings << "entry list is missing .page__content"
      return @warnings
    end

    nodes = content.element_children.select { |node| node.name == "article" || node.matches?(".pub_group") }
    unless nodes.any? { |node| node.name == "article" || node.at_xpath("./article") }
      @warnings << "entry list should display at least one entry"
    end
    check_entry_placement(content)

    index = 0
    @groups.each_with_index do |group, group_index|
      location = "group #{group_index + 1}"
      if group["title"]
        extra_articles = nodes.drop(index).take_while { |node| node.name == "article" }
        section = nodes[index + extra_articles.size]
        if section&.at_xpath("./h2")&.text == group["title"]
          extra_articles.each do |article|
            @warnings << "#{location} has unexpected entry #{heading_text(article).inspect} before its section"
          end
          index += extra_articles.size
        end
        node = nodes[index]
        check_group(group, node, "#{location} (#{group['title'].inspect})")
        index += 1 if node && node.name != "article"
      else
        entries = group.fetch("entries")
        articles = nodes.slice(index, entries.size).take_while { |node| node.name == "article" }
        check_entries(entries, articles, location, "h2")
        index += articles.size
      end
    end
    nodes.drop(index).each do |node|
      @warnings << "entry list has an unexpected <#{node.name}> with heading #{heading_text(node).inspect}"
    end
    @warnings
  end

  private

  def check_entry_placement(content)
    content.css("article").each do |article|
      parent = article.parent
      next if parent == content || (parent.parent == content && parent.matches?("section.pub_group"))

      @warnings << "entry #{heading_text(article).inspect} should appear directly under the page content or a titled group"
    end
  end

  def heading_text(node)
    node.at_css(HEADINGS)&.text
  end

  def check_group(group, node, location)
    return unless check_element(node, "section", location)

    heading = node.element_children.first
    check_heading(heading, "h2", group.fetch("title"), location)
    compare("#{location} anchor", group["id"], heading&.[]("id"))
    entries = group.fetch("entries")
    articles = node.xpath("./article")
    check_entries(entries, articles, location, "h3")
    check_extra_elements(location, entries.size, articles.size)
  end

  def check_entries(entries, nodes, group_location, heading_tag)
    entries.each_with_index do |entry, index|
      title = entry.fetch("title")
      location = "#{group_location}, entry #{index + 1} (#{title.inspect})"
      node = nodes[index]
      next unless check_element(node, "article", location)

      check_heading(node.at_css(HEADINGS), heading_tag, title, location)
      thumbnails = node.css(".pub_img img, .pub_img video")
      check_extra_elements("#{location} thumbnails", 1, thumbnails.size)
      check_url("#{location} thumbnail src", entry["image"], thumbnails.first&.[]("src"))
      check_links(entry, node, location)
    end
  end

  def check_links(entry, node, location)
    expected = Array(entry["links"]).map { |link| ["link", link] }
    venue = entry["venue"]
    expected.unshift(["venue", venue]) if venue && venue["url"]
    links = node.css("a")
    check_extra_elements("#{location} links", expected.size, links.size)
    expected.each_with_index do |(kind, link), index|
      label = link.fetch("label")
      link_location = "#{location}, #{kind} #{index + 1} (#{label.inspect})"
      actual = links[index]
      if actual
        compare("#{link_location} type", kind, actual.ancestors(".pub_venue").any? ? "venue" : "link")
        compare("#{link_location} label", label, actual.text)
      else
        @warnings << "#{link_location} is missing"
      end
      check_url("#{link_location} href", link["url"], actual&.[]("href"))
    end
  end

  def check_element(node, tag, location)
    return true if node&.name == tag

    @warnings << "#{location} should render as <#{tag}>, found #{node ? "<#{node.name}>" : 'nothing'}"
    false
  end

  def check_heading(heading, tag, title, location)
    location = "#{location} heading"
    compare("#{location} tag", tag, heading&.name)
    compare("#{location} text", title, heading&.text)
  end

  def check_extra_elements(location, expected, actual)
    return unless actual > expected

    @warnings << "#{location} expected #{expected} element(s), found #{actual}"
  end

  def compare(location, expected, actual)
    return if expected == actual

    @warnings << "#{location} expected #{expected.inspect}, found #{actual.inspect}"
  end

  def check_url(location, expected, actual)
    compare(location, expected, actual)
    [expected, actual || expected].uniq.each do |reference|
      issue = url_issue(reference)
      @warnings << "#{location}: #{reference.inspect} #{issue}" if issue
    end
  end

  def url_issue(reference)
    url = reference.to_s.strip
    return "is missing or empty" if url.empty?
    return if url.start_with?("#") || (url.start_with?("/") && !url.start_with?("//"))

    uri = Addressable::URI.parse(url)
    site_host = @site_url&.host
    if site_host && uri.host&.casecmp?(site_host)
      "uses the site's host and should start with /"
    elsif uri.relative? && !uri.host
      "is page-relative and should start with /"
    end
  rescue Addressable::URI::InvalidURIError
    "is an invalid URL"
  end
end
