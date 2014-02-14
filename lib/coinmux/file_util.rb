require 'fileutils'
require 'tmpdir'

module Coinmux::FileUtil
  import 'java.io.BufferedReader'
  import 'java.io.InputStreamReader'

  class << self
    def root_mkdir_p(*paths)
      begin
        FileUtils.mkdir_p(path = File.join(Coinmux.root, *paths))
      rescue
        FileUtils.mkdir_p(path = File.join(Dir.tmpdir, *paths))
      end

      path
    end

    def read_content(*paths)
      begin
        File.read(File.join(Coinmux.root, *paths))
      rescue
        # File.read was not working on Windows XP in a Jar file
        reader = nil
        begin
          stream = "".to_java.java_class.resource_as_stream("/#{paths.join('/')}")
          reader = BufferedReader.new(InputStreamReader.new(stream))
          content = StringIO.new
          while line = reader.readLine()
            content.puts(line)
          end
          content.string
        ensure
          reader.close() if reader
        end
      end
    end
  end
end