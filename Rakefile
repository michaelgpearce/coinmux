require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'warbler'
Warbler::Task.new

require './lib/coinmux/version'

namespace 'release' do
  task 'release' => [:jar, :tag]

  task 'tag' do
    system("git checkout origin master && git pull origin master && git tag -a v#{Coinmux::VERSION} -m '#{Coinmux::VERSION}' && git push --tags origin master") || fail("Unable to tag release")
  end

  task 'jar' do
    # Must set the environment variable before rake task is loaded
    system({'COINMUX_JAR_VERSION' => Coinmux::VERSION}, "bundle exec rake jar") || fail("Unable to build jar")
  end
end
