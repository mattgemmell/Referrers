#!/usr/bin/ruby

# Referrers
version = "1.0.0" # 2015-01-22
# 
# This script processes Apache access logs, and finds referrers.
# Output is via a template file (HTML by default).
# 
# Made by Matt Gemmell - mattgemmell.com - @mattgemmell
# 
# Github: http://github.com/mattgemmell/Referrers
# 
# Requirements: just Ruby itself, and its standard library.


# Defaults
config_file = "config.yml" #YAML file
exclusions_file = "exclusions.cfg" # Plain text file. Regexps, one per line.
input_file = "access.log*" # Filename, or shell glob pattern.
template_file = "template.html" # Text file of any kind.
newest_first = true # i.e. reverse chronological order
output_file = "report.html"


# Internal stuff for the template.
# Can all be overridden in the config file.
tag_start_delimiter = "{%"
tag_end_delimiter = "%}" # whitespace inside delimiters is ignored
row_start_tag = "row"
row_end_tag = "endrow"
result_url_tag = "url";
start_date_tag = "start_date";
end_date_tag = "end_date";
date_format_string = "%d %b, %Y at %H:%M:%S" # see http://ruby-doc.org/stdlib-2.2.0/libdoc/date/rdoc/DateTime.html#method-i-strftime


# Pay attention to any config options on the command line
require 'optparse'

OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"
	
	opts.on("-c", "--config CONFIG",
              "Use CONFIG as the configuration file") do |config|
              config_file = config;
	end
	
	opts.on("-e", "--exclusions EXCLUSIONS",
              "Use EXCLUSIONS as the exclusions file") do |exclusions|
		  exclusions_file = exclusions;
	end

	opts.on("-i", "--input INPUT",
              "Use INPUT as the input file, or file(s) pattern") do |input|
		  input_file = input;
	end
	
	opts.on("-t", "--template TEMPLATE",
              "Use TEMPLATE as the report template") do |template|
              template_file = template;
	end
	
	opts.on("-o", "--output OUTPUT",
              "Use OUTPUT as the output file") do |output|
              output_file = output;
	end
	
	opts.on("-f", "--oldest-first", "Sort oldest first") do
		newest_first = false
	end
	
	opts.on("-v", "--version", "Shows the version") do
		puts version
		exit
	end
end.parse!


# Load external config file
require "yaml"
config = YAML::load_file(config_file)


# Allow config file to override internal values
# Must be a nicer way to do this, but whatever.
if (!config["tag_start_delimiter"])
	config["tag_start_delimiter"] = tag_start_delimiter
end
if (!config["tag_end_delimiter"])
	config["tag_end_delimiter"] = tag_end_delimiter
end
if (!config["row_start_tag"])
	config["row_start_tag"] = row_start_tag
end
if (!config["row_end_tag"])
	config["row_end_tag"] = row_end_tag
end
if (!config["result_url_tag"])
	config["result_url_tag"] = result_url_tag
end
if (!config["start_date_tag"])
	config["start_date_tag"] = start_date_tag
end
if (!config["end_date_tag"])
	config["end_date_tag"] = end_date_tag
end
if (!config["date_format_string"])
	config["date_format_string"] = date_format_string
end


# Load relevant log file(s)
raw_content = []
log_files = []
file_counter = 0;
Dir.glob(input_file) {|file|
	file_counter += 1
	log_files.push file
	File.open(file, 'r') do |this_file|
		while line = this_file.gets
			raw_content.push line
		end
	end
}
puts "Loaded #{file_counter} log file(s) (#{log_files.join(", ")})"


# Extract just the entries with a referrer
referrer_regexp = /^[0-9.]+\s+\S+\s+\S+\s+\[[^\]]+\]\s+"[^"]+"\s+\d+\s+\d+\s+"(http([^"]{2,}))".+$/
referrers = raw_content.select{ |i| i[referrer_regexp] }

puts "Found #{referrers.count} referrers in #{raw_content.count} lines."
raw_content = []


# Normalise stupid Apache timestamps
# 91.6.204.133 - - [21/Jan/2015:08:04:38 +0000] "GET /css/print.css HTTP/1.1" 200 844 "http://mattgemmell.com/a-farewell-to-files/" "Mozilla/5.0"
timestamp_regexp = /\[(\d+\/[^\/]+\/[\d: +-]+)\]/
referrers.each_with_index { |val, index|
	# Extract timestamp
	timestamp = val.match(timestamp_regexp)[1]
	# Make a DateTime from it
	the_time = DateTime.strptime(timestamp, "%d/%b/%Y:%H:%M:%S %z")
	# Replace the entry with sensibly-formatted date, and the referral URL
	ref_url = val.match(referrer_regexp)[1]
	referrers[index] = "#{the_time.to_s}\t#{ref_url}"
}


# Sort results appropriately by timestamp
# We have to sort even if newest_first is false, because we might have concatenated multiple log files out of order
referrers.sort!
# Obtain date span for these logs
date_regexp = /^\S+/
raw_start_date = referrers.first.match(date_regexp).to_s
raw_end_date = referrers.last.match(date_regexp).to_s
start_date = DateTime.strptime(raw_start_date)
end_date = DateTime.strptime(raw_end_date)
puts "These logs cover the period #{start_date.strftime(config["date_format_string"])} to #{end_date.strftime(config["date_format_string"])}."
# Respect desired sort order
if (newest_first)
	referrers.reverse!
end


# Extract just the referral URLs themselves
ref_url_regexp = /http.+$/
referrers.each_with_index { |val, index|
	# Extract just referral URL
	ref_url = val.match(ref_url_regexp).to_s
	# Replace the entry with just the URL
	referrers[index] = ref_url
}


# Remove duplicates
referrers = referrers.uniq
puts "There are #{referrers.count} unique referrers."


# Process the external exclusions file
# Load the exclusions
exclusions = []
File.open(exclusions_file, 'r') do |excl_file|
	while line = excl_file.gets
		if (line != "\n")
			exclusions.push line
		end
	end
end
puts "Loaded #{exclusions.count} exclusion patterns."
# Filter each referral URL against all exclusions
filtered_referrers = []
referrers.each { |ref_url|
	excluded = false
	exclusions.each { |excl_pattern|
		# Create regexp from pattern
		excl_regexp = Regexp.new(excl_pattern.strip, Regexp::IGNORECASE);
		# Check for a match
		if (ref_url =~ excl_regexp)
			#puts "Excluding #{ref_url}; matches #{excl_pattern}"
			excluded = true
			break
		end
	}
	if (!excluded)
		filtered_referrers.push ref_url
	end
}
puts "Excluded #{referrers.count - filtered_referrers.count} referrers."
puts "There are #{filtered_referrers.count} qualifying referrers."


# Generate output via template and tags
template_tags_key = "template_tags"

# Load template file
template_raw_contents = ""
File.open(template_file, 'r') do |excl_file|
	while line = excl_file.gets
		template_raw_contents += line;
	end
end

# Split template into relevant sections
report_chunks = []
delim_pre_pattern = "#{config["tag_start_delimiter"]}\s*"
delim_post_pattern = "\s*#{config["tag_end_delimiter"]}"

# Obtain pre-rows chunk
row_start_tag_pattern = "#{delim_pre_pattern}#{config["row_start_tag"]}#{delim_post_pattern}"
pre_rows_regexp = Regexp.new("(^.*)#{row_start_tag_pattern}", Regexp::MULTILINE | Regexp::IGNORECASE);
template_pre_rows_chunk = template_raw_contents.match(pre_rows_regexp)[1]
report_chunks.push template_pre_rows_chunk

# Obtain repeating row chunk, WITHOUT delimiters
row_end_tag_pattern = "#{delim_pre_pattern}#{config["row_end_tag"]}#{delim_post_pattern}"
row_regexp = Regexp.new("#{row_start_tag_pattern}(.*)#{row_end_tag_pattern}", Regexp::MULTILINE | Regexp::IGNORECASE);
template_row_repeating_chunk = template_raw_contents.match(row_regexp)[1]

# Assemble row chunks, with substituted URLs
url_tag_pattern = "#{delim_pre_pattern}#{config["result_url_tag"]}#{delim_post_pattern}"
url_regexp = Regexp.new(url_tag_pattern, Regexp::IGNORECASE)
filtered_referrers.each { |ref_url|
	report_chunks.push template_row_repeating_chunk.gsub(url_regexp, ref_url)
}

# Obtain post-rows chunk
post_rows_regexp = Regexp.new("#{row_end_tag_pattern}(.*$)", Regexp::MULTILINE | Regexp::IGNORECASE)
template_post_rows_chunk = template_raw_contents.match(post_rows_regexp)[1]
report_chunks.push template_post_rows_chunk

# Process static tags in all chunks: dates, and user's template tags
report_contents = report_chunks.join()
# Replace start-date tags
start_date_tag_pattern = "#{delim_pre_pattern}#{config["start_date_tag"]}#{delim_post_pattern}"
date_format_string = config["date_format_string"]
start_date_regexp = Regexp.new(start_date_tag_pattern, Regexp::IGNORECASE)
report_contents = report_contents.gsub(start_date_regexp, start_date.strftime(config["date_format_string"]))
# Replace end-date tags
end_date_tag_pattern = "#{delim_pre_pattern}#{config["end_date_tag"]}#{delim_post_pattern}"
end_date_regexp = Regexp.new(end_date_tag_pattern, Regexp::IGNORECASE)
report_contents = report_contents.gsub(end_date_regexp, end_date.strftime(config["date_format_string"]))
# Replace the user's template tags
config[template_tags_key].each { |key, val|
	tag_regexp = Regexp.new("#{delim_pre_pattern}#{key}#{delim_post_pattern}", Regexp::IGNORECASE)
	report_contents = report_contents.gsub(tag_regexp, val)
}


# Output the resulting report
File.open(output_file, 'w') do |outfile|
  outfile.puts report_contents
end
puts "Report created: \"#{output_file}\"."
puts "Done."

