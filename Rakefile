require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :version do
  desc "Show the current gem version"
  task :show do
    system <<-SHELL
      bump current
    SHELL
  end

  namespace :bump do
    desc "Bump the gem one major version"
    task :major do
      system "bump major"
    end

    desc "Bump the gem one minor version"
    task :minor do
      system "bump minor"
    end

    desc "Bump the gem one patch version"
    task :patch do
      system "bump patch"
    end
  end
end