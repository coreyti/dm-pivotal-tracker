require 'rubygems'
require 'dm-core'

dir = File.join(File.dirname(__FILE__), 'datamapper')

Dir["#{dir}/**/*.rb"].each do |file|
  require file
end
