require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'pivotal_tracker'

describe DataMapper::Adapters::PivotalAdapter do
  it_should_behave_like 'a DataMapper Adapter'
  
  describe "create" do
    it "is pending" do
      pending
    end
  end
  
  describe "read" do
    describe "PivotalAdapter#read_one" do
      context "when the Resource exists" do
        before do
          mock_get('http://www.pivotaltracker.com/services/v1/projects/1') do
            <<-XML
            <response success="true">
              <project>
                <name>Sample Project</name>
              </project>
            </response>
            XML
          end
        end
        
        it "executes an HTTP GET" do
          PivotalTracker::Project.get(1)
        end
        
        it "returns the Resource" do
          resource = PivotalTracker::Project.get(1)
          resource.should_not be_nil
          resource.id.should be_an_instance_of(Fixnum)
          resource.id.should == 1
          resource.should be_an_instance_of(PivotalTracker::Project)
        end
      end
      
      context "when the Resource does not exist" do
        before do
          mock_get('http://www.pivotaltracker.com/services/v1/projects/1') do
            Net::HTTPNotFound
          end
        end
        
        it "returns nil" do
          resource = PivotalTracker::Project.get(1)
          resource.should be_nil
        end
      end

      context "when the Resource is found as a nested Resource" do
        before do
          mock_get('http://www.pivotaltracker.com/services/v1/projects/1/stories/100') do
            <<-XML
            <response success="true">
              <story>
                <id type="integer">100</id>
                <name>Sample Story</name>
              </story>
            </response>
            XML
          end
        end

        describe "finding via a foreign key" do
          it "executes an HTTP GET with the Resource ancestry in the URL" do
            pending
            PivotalTracker::Story.first(:project_id => 1)
          end

          it "returns the nested Resource" do
            pending
          end
        end
        
        describe "finding via an association" do
          it "executes an HTTP GET with the Resource ancestry in the URL" do
            pending
            PivotalTracker::Project.get(1).stories.first
          end

          it "returns the nested Resource" do
            pending
          end
        end
      end
    end
    
    describe "PivotalAdapter#read_many" do
      context "when at least one Resource exists" do
        before do
          mock_get('http://www.pivotaltracker.com/services/v1/projects/1') do
            <<-XML
            <response success="true">
              <project>
                <name>Sample Project</name>
              </project>
            </response>
            XML
          end

          mock_get('http://www.pivotaltracker.com/services/v1/projects/1/stories') do
            <<-XML
            <response success="true">
              <stories count="2">
                <story>
                  <id type="integer">100</id>
                  <name>Story One</name>
                </story>
                <story>
                  <id type="integer">200</id>
                  <name>Story Two</name>
                </story>
              </stories>
            </response>
            XML
          end
        end

        it "executes an HTTP GET" do
          project = PivotalTracker::Project.get(1)
          stories = project.stories.all(:id.gt => 0)

          stories.length.should == 2
          stories[0].id.should == 100
          stories[1].id.should == 200
        end
        
        it "uh oh, how about with Resource#all with no args" do
          pending
          project = PivotalTracker::Project.get(1)
          project.stories.all
        end
        
        it "returns a list of Resources, one per response XML entry" do
          pending
        end
      end
      
      context "when a Resource does not exist" do
        it "returns an empty list" do
          pending
        end
      end
    end
  end

  describe "update" do
    it "is pending" do
      pending
    end
  end

  describe "delete" do
    it "is pending" do
      pending
    end
  end
end
