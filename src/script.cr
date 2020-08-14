# A script to batch create a series of .cr files from .json ones
require "./jenerator"

json_filename_pattern = /(.+)\.json/
input_dir = ARGV[0]? || "./src"

Dir.each_child input_dir do |filepath|
  if json_filename_pattern =~ filepath
    File.open filepath do |data|
      File.write $1 + ".cr", Jenerator.process data, document_name: $1
    end
  end
end
