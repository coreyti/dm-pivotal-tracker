require File.join(File.dirname(__FILE__), %w[.. spec_helper])

require "pivotal_tracker/story"
require "pivotal_tracker/iteration"

describe PivotalTracker::Story do
  it "finds the adapter (specified in spec_helper)" do
    adapter.should_not be_nil
  end
end