require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'warbler'
Warbler::Task.new

namespace 'release' do
  task 'jar' do
    raise "You must set COINMUX_JAR_VERSION in the environment" if ENV['COINMUX_JAR_VERSION'].nil?
    Rake::Task['jar'].invoke
  end
end
