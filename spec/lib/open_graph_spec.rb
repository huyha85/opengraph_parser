require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenGraph do
  describe "#initialize" do
    context "with invalid src" do
      it "should set title and url the same as src" do
        og = OpenGraph.new("invalid")
        og.src.should == "invalid"
        og.title.should == "invalid"
        og.url.should == "invalid"
      end
    end

    context "with redirect_limit in options hash" do
      it "should pass redirect_limit to RedirectFollower" do
        RedirectFollower.should_receive(:new).with("http://test.host", redirect_limit: 20)

        og = OpenGraph.new("http://test.host", redirect_limit: 20)
      end
    end

    context "with no fallback" do
      it "should get values from opengraph metadata" do
        response = double(body: File.open("#{File.dirname(__FILE__)}/../view/opengraph.html", 'r') { |f| f.read })
        RedirectFollower.stub(:new) { double(resolve: response) }

        og = OpenGraph.new("http://test.host", false)
        og.src.should == "http://test.host"
        og.title.should == "OpenGraph Title"
        og.type.should == "article"
        og.url.should == "http://test.host"
        og.description.should == "My OpenGraph sample site for Rspec"
        og.images.should == ["http://test.host/images/rock1.jpg", "http://test.host/images/rock2.jpg"]
        og.original_images.should == ["http://test.host/images/rock1.jpg", "/images/rock2.jpg"]
        og.metadata.should == {
          title: [{_value: "OpenGraph Title"}],
          type: [{_value: "article"}],
          url: [{_value: "http://test.host"}],
          description: [{_value: "My OpenGraph sample site for Rspec"}],
          image: [
            {
              _value: "http://test.host/images/rock1.jpg",
              width: [{ _value: "300" }],
              height: [{ _value: "300" }]
            },
            {
              _value: "/images/rock2.jpg",
              height: [{ _value: "1000" }]
            }
          ],
          locale: [
            {
              _value: "en_GB",
              alternate: [
                { _value: "fr_FR" },
                { _value: "es_ES" }
              ]
            }
          ]
        }
      end
    end

    context "with fallback" do
      context "when website has opengraph metadata" do
        it "should get values from opengraph metadata" do
          response = double(body: File.open("#{File.dirname(__FILE__)}/../view/opengraph.html", 'r') { |f| f.read })
          RedirectFollower.stub(:new) { double(resolve: response) }

          og = OpenGraph.new("http://test.host")
          og.src.should == "http://test.host"
          og.title.should == "OpenGraph Title"
          og.type.should == "article"
          og.url.should == "http://test.host"
          og.description.should == "My OpenGraph sample site for Rspec"
          og.images.should == ["http://test.host/images/rock1.jpg", "http://test.host/images/rock2.jpg"]
        end
      end

      context "when website has no opengraph metadata" do
        it "should lookup for other data from website" do
          response = double(body: File.open("#{File.dirname(__FILE__)}/../view/opengraph_no_metadata.html", 'r') { |f| f.read })
          RedirectFollower.stub(:new) { double(resolve: response) }

          og = OpenGraph.new("http://test.host/child_page")
          og.src.should == "http://test.host/child_page"
          og.title.should == "OpenGraph Title Fallback"
          og.type.should be_nil
          og.url.should == "http://test.host/child_page"
          og.description.should == "Short Description Fallback"
          og.images.should == ["http://test.host/images/wall1.jpg", "http://test.host/images/wall2.jpg"]
        end
      end

      context "when website has no opengraph metadata nor description" do
        it "should lookup for other data from website" do
          response = double(body: File.open("#{File.dirname(__FILE__)}/../view/opengraph_no_meta_nor_description.html", 'r') { |f| f.read })
          RedirectFollower.stub(:new) { double(resolve: response) }

          og = OpenGraph.new("http://test.host/child_page")
          og.src.should == "http://test.host/child_page"
          og.title.should == "OpenGraph Title Fallback"
          og.type.should be_nil
          og.url.should == "http://test.host/child_page"
          og.description.should == "No description meta here."
          og.images.should == ["http://test.host/images/wall1.jpg", "http://test.host/images/wall2.jpg"]
        end
      end
    end

    context "with body" do
      context "with comment on html" do
        it "should parse body instead of downloading it" do
          content = File.read("#{File.dirname(__FILE__)}/../view/opengraph_comment_on_html.html")

          RedirectFollower.should_not_receive(:new)

          og = OpenGraph.new(content)
          og.src.should == content
          og.title.should == "OpenGraph Title"
          og.type.should == "article"
          og.url.should == "http://test.host"
          og.description.should == "My OpenGraph sample site for Rspec"
          og.images.should == ["http://test.host/images/rock1.jpg", "http://test.host/images/rock2.jpg"]
        end

      end

      it "should parse body instead of downloading it" do
        content = File.read("#{File.dirname(__FILE__)}/../view/opengraph.html")
        RedirectFollower.should_not_receive(:new)

        og = OpenGraph.new(content)
        og.src.should == content
        og.title.should == "OpenGraph Title"
        og.type.should == "article"
        og.url.should == "http://test.host"
        og.description.should == "My OpenGraph sample site for Rspec"
        og.images.should == ["http://test.host/images/rock1.jpg", "http://test.host/images/rock2.jpg"]
      end
    end
  end
end
