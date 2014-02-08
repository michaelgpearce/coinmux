require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'warbler'
Warbler::Task.new

require './lib/coinmux/version'

namespace 'release' do
  task 'release' => [:gitupdate, :jar, :readme, :tag]

  task 'readme' => 'gitupdate' do
    system("sed 's/The latest version is.*/The latest version is: #{Coinmux::VERSION}/' README.md > README.tmp && mv README.tmp README.md") || fail("Unable to replace version in README")
    system("git add README.md && git commit -m '#{Coinmux::VERSION}' && git push origin master") || fail("Unable to push README")
  end

  task 'tag' => 'gitupdate' do
    system("git tag -a v#{Coinmux::VERSION} -m '#{Coinmux::VERSION}' && git push --tags origin && git push origin master") || fail("Unable to tag release")
  end

  task 'jar' do
    # Must set the environment variable before rake task is loaded
    system({'COINMUX_JAR_VERSION' => Coinmux::VERSION}, "bundle exec rake jar") || fail("Unable to build jar")
  end

  task 'gitupdate' do
    system("git checkout master && git pull origin master") || fail("Unable to checkout / pull master")
  end
end
