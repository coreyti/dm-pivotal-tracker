require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'pivotal_tracker'

describe DataMapper::Adapters::PivotalAdapter do
  it_should_behave_like 'a DataMapper Adapter'
  
  describe "create" do
    describe "basic initial coverage" do
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
            <stories count="1">
              <story>
                <id type="integer">100</id>
                <name>Story One</name>
              </story>
            </stories>
          </response>
          XML
        end

        mock_post(
          'http://www.pivotaltracker.com/services/v1/projects/1/stories',
          '<story><name>Sample Story</name></story>'
        ) do
          <<-XML
          <response success="true">
            <story>
              <id type="integer">200</id>
              <name>Sample Story</name>
            </story>
          </response>
          XML
        end
      end

      it "succeeds" do
        pending "fixes to mock order issues"
        project = PivotalTracker::Project.get(1)
        story = project.stories.create(:name => 'Sample Story')
        story.should_not be_nil
        story.id.should be_an_instance_of(Fixnum)
        story.id.should == 200
        story.should be_an_instance_of(PivotalTracker::Story)
      end
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
          project = PivotalTracker::Project.get(1)
          project.should_not be_nil
          project.id.should be_an_instance_of(Fixnum)
          project.id.should == 1
          project.should be_an_instance_of(PivotalTracker::Project)
        end
      end
      
      context "when the Resource does not exist" do
        before do
          mock_get('http://www.pivotaltracker.com/services/v1/projects/1') do
            Net::HTTPNotFound
          end
        end
        
        it "returns nil" do
          project = PivotalTracker::Project.get(1)
          project.should be_nil
        end
      end

      context "when the token does not allow access to the Resource" do
        it "either returns nil, or raises (TBD)" do
          pending
          # response: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<response success=\"false\">\n <message>The authenticated user for this token is not allowed to view this project</message>\n</response>\n" result nil
        end
      end
      
      context "when the Resource is found as a nested Resource" do
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
              <stories count="1">
                <story>
                  <id type="integer">100</id>
                  <name>Story One</name>
                </story>
              </stories>
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
          it "returns the nested Resource" do
            story = PivotalTracker::Project.get(1).stories.get(100)
            story.should_not be_nil
            story.id.should be_an_instance_of(Fixnum)
            story.id.should == 100
            story.should be_an_instance_of(PivotalTracker::Story)
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
          project.stories.all.length
        end

        it "returns a list of Resources, one per response XML entry" do
          project = PivotalTracker::Project.get(1)
          stories = project.stories.all

          stories.length.should == 2
          stories[0].id.should == 100
          stories[1].id.should == 200
        end
      end

      context "when a Resource does not exist" do
        it "returns an empty list" do
          pending
        end
      end

      context "when invoked via Resource#all, with limiting conditions" do
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

        it "returns a list of Resources, one per response XML entry" do
          project = PivotalTracker::Project.get(1)
          lambda do
            stories = project.stories.all(:name => 'Story Two')
          end.should raise_error(NotImplementedError)
        end
      end
    end
  end

  describe "update" do
    context "when the Resource exists" do
      attr_reader :story, :new_attributes
      
      before do
        @new_attributes = { :name => 'New Story Name' }

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
            <stories count="1">
              <story>
                <id type="integer">100</id>
                <name>Story One</name>
              </story>
            </stories>
          </response>
          XML
        end

        @story = PivotalTracker::Project.get(1).stories.get(100)
      end
      
      it "updates the Resource" do
        mock_put(
          'http://www.pivotaltracker.com/services/v1/projects/1/stories/100',
          "<story><name>#{new_attributes[:name]}</name></story>"
        ) do
          Net::HTTPSuccess.new(nil, nil, nil)
        end

        story.update_attributes(new_attributes).should be_true
      end
    end
  end

  describe "delete" do
    context "when the Resource exists" do
      attr_reader :story

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
            <stories count="1">
              <story>
                <id type="integer">100</id>
                <name>Story One</name>
              </story>
            </stories>
          </response>
          XML
        end

        @story = PivotalTracker::Project.get(1).stories.get(100)
      end

      it "deletes the Resource" do
        mock_delete('http://www.pivotaltracker.com/services/v1/projects/1/stories/100') do
          <<-XML
          <response success="true">
            <message>Story 100 was deleted</message>
          </response>
          XML
        end

        story.destroy.should be_true
      end
    end
  end
end
