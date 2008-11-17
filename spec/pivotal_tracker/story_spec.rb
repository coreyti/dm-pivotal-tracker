require File.join(File.dirname(__FILE__), %w[.. spec_helper])

require "pivotal_tracker/story"
require "pivotal_tracker/iteration"

describe PivotalTracker::Story do
  include PivotalTracker

  attr_reader :adapter
  
  before(:all) do
    DataMapper.setup(:pivotal, { :adapter => 'pivotal' })
    @adapter = DataMapper::Repository.adapters[:pivotal]
  end

  describe "current?" do
    it "returns false if the iteration is nil" do
      story = PivotalTracker::Story.new()
      story.should_not be_current
    end

    it "returns true if the today falls within the iteration's start & end date" do
      iteration = PivotalTracker::Iteration.new(:number => 1, :start => Date.today - 7, :finish => Date.today + 7)
      story     = PivotalTracker::Story.new(:iteration => iteration)
      story.should be_current
    end
  end
end