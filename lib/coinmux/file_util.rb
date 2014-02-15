require 'fileutils'
require 'tmpdir'

module Coinmux::FileUtil
  import 'java.io.FileInputStream'
  import 'java.io.InputStreamReader'
  import 'java.io.ByteArrayOutputStream'
  import 'java.io.IOException'

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
      Java::JavaLang::String.new(read_content_as_java_bytes(*paths)).to_s
    end

    def read_content_as_java_bytes(*paths)
      begin
        input_stream = begin
          FileInputStream.new(File.join(Coinmux.root, *paths)) # file system
        rescue IOException => e
          "".to_java.java_class.resource_as_stream("/#{paths.join('/')}") # Jar file
        end

        read_java_bytes(input_stream)
      ensure
        input_stream.close() if input_stream
      end
    end

    private

    def read_java_bytes(input_stream)
      buffer = Java::byte[8192].new
      output_stream = ByteArrayOutputStream.new
      while (bytes_read = input_stream.read(buffer)) >= 0
        output_stream.write(buffer, 0, bytes_read)
      end
      output_stream.toByteArray()
    end
  end
end