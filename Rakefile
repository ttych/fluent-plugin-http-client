# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'bump/tasks'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs.push('lib', 'test')
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
  t.warning = true
end

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rake'
end

task default: %i[test rubocop]
