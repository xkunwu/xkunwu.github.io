require "json"
require "nokogiri"
require "yaml"

def check(condition, message)
  abort "Site check failed: #{message}" unless condition
end

def site_file(path)
  file = File.join("_site", path)
  check(File.file?(file) && !File.zero?(file), "missing or empty #{file}")
  File.read(file, encoding: "UTF-8")
end

page_titles = {
  "index.html" => "Welcome to WU Xiaokun’s homepage!",
  "teach/index.html" => "Teach",
  "research/index.html" => "Research",
  "projects/index.html" => "Projects",
  "projects/hand-track/hand-track.html" => "Hand detection and tracking"
}

pages = page_titles.to_h do |path, title|
  page = Nokogiri::HTML(site_file(path))
  check(page.at_css("#page-title")&.text&.strip == title, "#{path} should show #{title}")
  check(page.at_css('link[rel="stylesheet"][href="/assets/css/main.css"]'), "#{path} should load the theme CSS")
  copyright = page.at_css('.page__footer-copyright a[href="/COPYRIGHT.txt"]')
  check(copyright&.text&.match?(/\A2018 - \d{4} WU Xiaokun\.\z/), "#{path} should show the copyright link")
  [path, page]
end

css = site_file("assets/css/main.css")
%w[.masthead .pub_row].each do |selector|
  check(css.include?(selector), "theme CSS should include #{selector}")
end
site_file("COPYRIGHT.txt")

projects = pages.fetch("projects/index.html")
check(projects.at_css('.pub_row a[href="hand-track/hand-track"]'), "projects should link to Hand Track")
check(pages.fetch("research/index.html").at_css(".pub_row .pub_txt"), "research should show its publications")

detail = pages.fetch("projects/hand-track/hand-track.html")
%w[assumptions faq].each do |heading|
  check(detail.at_css(".toc__menu a[href='##{heading}']") && detail.at_css("##{heading}"),
        "Hand Track should link to ##{heading} from its table of contents")
end

catalog = YAML.safe_load_file("_data/teaching.yml")
courses = catalog.fetch("current") + catalog.fetch("archive")
rows = pages.fetch("teach/index.html").css(".pub_row .pub_txt")
check(rows.size == courses.size, "teaching catalog should show #{courses.size} course rows")

courses.zip(rows).each do |course, row|
  directory = course.fetch("directory")
  terms = course.fetch("terms")
  expected_links = terms.map { |term| ["#{directory}/#{term.fetch('file')}", term.fetch("label")] }
  links = row.css("links a").map { |link| [link["href"], link.text.strip] }
  check(row.at_css("title")&.text == course.fetch("title") && links == expected_links,
        "teaching catalog should show #{directory} with its terms in order")
  expected_links.each { |path, _| site_file("teach/#{path}") }

  default_file = terms.first.fetch("file")
  entry_path = "teach/#{directory}/index.html"
  entry = Nokogiri::HTML(site_file(entry_path))
  refresh = entry.at_css('meta[http-equiv="refresh"]')&.[]("content")
  check(refresh == "0; url=#{default_file}", "#{entry_path} should refresh to #{default_file}")
  script = entry.css("script").map(&:text).join("\n")
  target = script[/window\.location\.href\s*=\s*("(?:[^"\\]|\\.)*")\s*;/, 1]
  check(target && JSON.parse(target) == default_file, "#{entry_path} should navigate to #{default_file}")
  fallback = entry.at_css("body a")
  check(fallback && fallback["href"] == default_file && fallback.text.strip == terms.first.fetch("label"),
        "#{entry_path} should link to #{default_file} as a fallback")
end

%w[Gemfile.lock scripts/check-site.rb vendor/bundle].each do |path|
  check(!File.exist?(File.join("_site", path)), "#{path} should be excluded from the site")
end

puts "Verified #{pages.size} pages, theme CSS, Hand Track contents, copyright, and #{courses.size} course entries and their terms."
