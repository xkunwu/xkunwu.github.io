require "fileutils"
require "jekyll"
require "minitest/autorun"
require "nokogiri"
require "tmpdir"

class RasterSlidesTest < Minitest::Test
  def test_builds_matching_slide_and_thumbnail_sequences
    with_deck(%w[103.jpg 003.jpg 000.jpg 001.jpg cover.jpg 00a.jpg 0+1.jpg １２３.jpg
                 12.jpg 1000.jpg 004.JPG 005.png nested/002.jpg]) do |page|
      expected = %w[000.jpg 001.jpg 003.jpg 103.jpg]
      assert_equal "Fixture deck", page.at_css("title")&.text
      assert_equal expected, page.css("#slides img").map { |image| image["src"] }
      assert_equal expected, page.css("#thumbnails img").map { |image| image["src"] }
      assert_equal ["000.jpg"], page.css("#slides img:not([hidden])").map { |image| image["src"] }
      assert_equal ["000.jpg"], page.css('#thumbnails [aria-current="true"] img').map { |image| image["src"] }
    end
  end

  def test_shows_a_message_and_no_controls_for_an_empty_deck
    with_deck([]) do |page|
      assert_includes page.at_css("main").text, "No slides are available."
      assert_empty page.css("main img, main button")
    end
  end

  def test_displays_the_only_slide_and_marks_its_thumbnail
    with_deck(["009.jpg"]) do |page|
      assert_equal ["009.jpg"], page.css("#slides img:not([hidden])").map { |image| image["src"] }
      assert_equal ["009.jpg"], page.css('#thumbnails [aria-current="true"] img').map { |image| image["src"] }
    end
  end

  private

  def with_deck(files)
    Dir.mktmpdir do |source|
      output = File.join(source, "_site")
      FileUtils.mkdir_p(File.join(source, "_layouts"))
      layout = File.expand_path("../_layouts/raster-slides.html", __dir__)
      FileUtils.cp(layout, File.join(source, "_layouts"))
      deck = File.join(source, "teach", "Fixture", "raster", "deck")
      FileUtils.mkdir_p(deck)
      File.write(File.join(deck, "index.html"), <<~YAML)
        ---
        layout: raster-slides
        title: Fixture deck
        regenerate: true
        ---
      YAML
      files.each do |name|
        file = File.join(deck, name)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, "fixture")
      end

      site = Jekyll::Site.new(Jekyll.configuration(
        "source" => source, "destination" => output, "safe" => true, "quiet" => true
      ))
      site.process
      yield Nokogiri::HTML(File.read(File.join(output, "teach/Fixture/raster/deck/index.html")))
    end
  end
end
