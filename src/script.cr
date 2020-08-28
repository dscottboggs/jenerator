# A script to batch create a series of .cr files from .json ones
require "http"
require "uri"
require "./jenerator"

JSON_FILENAME_PATTERN = /(.+)\.json/

def convert(json_file, parent_dir = Path.new Dir.current) : Bool
  if JSON_FILENAME_PATTERN =~ json_file
    File.open parent_dir / json_file do |data|
      File.open parent_dir / ($1 + ".cr"), mode: "w+" do |output|
        Jenerator.process data, document_name: $1, into: output
        return true
      end
    end
  end
  false
end

done = Channel(Bool).new ARGV.size

args = ARGV.map(&->Path.new(String))

while input = args.shift?
  begin
    # debugger
    if File.directory? input
      Dir.each_child(input) { |file| convert file, input }
    elsif File.file? input
      convert input
    else
      uri = URI.parse input.to_s
      if (response = HTTP::Client.get uri).success?
        output = args.shift? || uri.path
        File.open output, mode: "w" do |file|
          Jenerator.process response.body || response.body_io, document_name: output, into: file
        end
      else
        STDERR.puts "file/directory not found, and failed to fetch resource at #{uri}"
      end
    end
  rescue e : URI::Error
    STDERR.puts "no file found at #{input}, which also failed to be parsed as a URI due to #{e.message}"
  end
end
