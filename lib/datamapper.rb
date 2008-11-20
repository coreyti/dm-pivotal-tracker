require 'rubygems'
require 'dm-core'

gem 'extlib', '~>0.9.8'
require 'extlib'

dir = File.join(File.dirname(__FILE__), 'datamapper')

Dir["#{dir}/**/*.rb"].each do |file|
  require file
end
