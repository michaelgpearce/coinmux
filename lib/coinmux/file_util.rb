require 'fileutils'
require 'tmpdir'

module Coinmux::FileUtil
  class << self
    def root_mkdir_p(*paths)
      begin
        FileUtils.mkdir_p(path = File.join(Coinmux.root, *paths))
      rescue
        FileUtils.mkdir_p(path = File.join(Dir.tmpdir, *paths))
      end

      path
    end
  end
end