require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require './lib/coinmux/version'

namespace 'release' do
  task 'release' => 'gitupdate' do
    Rake::Task['jar'].invoke("coinmux-#{Coinmux::VERSION}.jar")
    Rake::Task['release:readme'].invoke
    Rake::Task['release:tag'].invoke
  end

  task 'readme' => 'gitupdate' do
    system("sed 's/The latest version is.*/The latest version is: #{Coinmux::VERSION}/' README.md > README.tmp && mv README.tmp README.md") || fail("Unable to replace version in README")
    system("git add README.md && git commit -m '#{Coinmux::VERSION}' && git push origin master") || fail("Unable to push README")
  end

  task 'tag' => 'gitupdate' do
    system("git tag -a v#{Coinmux::VERSION} -m '#{Coinmux::VERSION}' && git push --tags origin && git push origin master") || fail("Unable to tag release")
  end

  task 'gitupdate' do
    system("git checkout master && git pull origin master") || fail("Unable to checkout / pull master")
  end
end

task 'jar', :jar_name do |t, args|
  require 'bundler'
  require 'fileutils'

  jar_name = args[:jar_name] ||= "coinmux-SNAPSHOT.jar"

  jruby_jars_gem = Bundler.load.specs.detect { |spec| spec.name == "jruby-jars" && spec.version.version == JRUBY_VERSION } || fail("Unable to find jruby-jars-#{JRUBY_VERSION}")

  begin
    root = File.dirname(File.expand_path(__FILE__))
    build_jar_path = File.join(root, 'build', 'jar')
    FileUtils.rm_rf(build_jar_path)
    FileUtils.mkdir_p(build_jar_path)

    Dir.chdir(build_jar_path) do
      Dir[File.join(jruby_jars_gem.full_gem_path, 'lib', '*.jar')].each do |jar_path|
        system("jar xf \"#{jar_path}\"")
      end
      Dir[File.join(root, 'lib', 'jar', '*.jar')].each do |jar_path|
        system("jar xf \"#{jar_path}\"")
      end
      %w(bin cli config gui lib).each do |dir|
        FileUtils.cp_r(File.join(root, dir), build_jar_path)
      end
      File.open('jar-bootstrap.rb', 'w') do |f|
        f << "load 'bin/coinmux'" # Windows XP only likes load here
      end
      system("jar cfe \"#{File.join(root, jar_name)}\" org.jruby.JarBootstrapMain .") || fail("Unable to create jar file")
    end
  ensure
    FileUtils.rm_rf(build_jar_path)
  end
end
