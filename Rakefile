require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'yard'
require 'esub'

RSpec::Core::RakeTask.new

YARD::Rake::YardocTask.new

desc 'Open console for the project'
task :console do
  sh 'pry --gem', :verbose => false
end

task :default => [:spec]
