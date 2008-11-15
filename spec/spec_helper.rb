require "rubygems"
require "spec"

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), %w[lib])
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), %w[.. lib])

Spec::Runner.configure do |config|
  config.mock_with :rr
end
