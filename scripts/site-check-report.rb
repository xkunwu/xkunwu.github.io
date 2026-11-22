require "set"

class SiteCheckReport
  def initialize
    @warnings = Set.new
    @missing_outputs = Set.new
    @incomplete_reasons = Set.new
  end

  def warning(source, message)
    @warnings.add([source, message])
  end

  def missing_output(source, path)
    warning(source, "missing or empty #{path}") if @missing_outputs.add?(File.expand_path(path))
  end

  def incomplete(source, reason)
    @incomplete_reasons.add([source, reason])
  end

  def write
    headline = format_headline
    lines = format_findings
    puts headline, *lines

    summary = ENV["GITHUB_STEP_SUMMARY"]
    return if summary.nil? || summary.empty?

    File.open(summary, "a") do |file|
      file.puts "## Site check", "", headline, ""
      lines.each { |line| line.each_line { |part| file.puts "    #{part}" } }
      file.puts "" unless lines.empty?
    end
  end

  private

  def format_headline
    warnings = @warnings.empty? ? "no warnings" : "#{@warnings.size} warning(s)"
    return "Site check completed with #{warnings}." if @incomplete_reasons.empty?

    "Site check incomplete with #{warnings} and #{@incomplete_reasons.size} incomplete reason(s)."
  end

  def format_findings
    incomplete = @incomplete_reasons.map { |source, reason| [source, "Check incomplete: #{reason}"] }
    (@warnings.to_a + incomplete).group_by(&:first).sort.flat_map do |source, findings|
      [source, *findings.map(&:last).sort.map { |message| "  - #{message}" }]
    end
  end
end
