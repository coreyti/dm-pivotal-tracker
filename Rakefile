require 'rake'
require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ['--options', "spec/spec.opts"] if File.exist?("spec/spec.opts")
  t.spec_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec