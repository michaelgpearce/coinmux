require 'fileutils'

module Coinmux::FileUtil
  class << self
    def root_mkdir_p(*path)
      begin
        FileUtils.mkdir_p(path = File.join(Coinmux.root, *path))
      rescue
        FileUtils.mkdir_p(path = File.join('.', *path))
      end

      path
    end
  end
end