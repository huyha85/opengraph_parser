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

      context "when the website has bad og tags" do
        it "should not throw an exception parsing images" do
          response = double(body: File.open("#{File.dirname(__FILE__)}/../view/opengraph_bad_url.html", 'r') { |f| f.read })
          RedirectFollower.stub(:new) { double(resolve: response) }

          og = OpenGraph.new("http://www.sutd.edu.sg/")
          og.src.should == "http://www.sutd.edu.sg/"
          og.title.should == "Home | SUTD Singapore University of Technology and Design"
          og.type.should be_nil
          og.url.should == "http://www.sutd.edu.sg/"
          og.description.should == "The Singapore University of Technology and Design is established in collaboration with MIT to advance knowledge and nurture technically grounded leaders and innovators to serve societal needs."
          og.images.should == ["http://www.sutd.edu.sg/images/logo_white.png", "http://www.sutd.edu.sg/images/topsecnav-dropdown.png", "http://www.sutd.edu.sg/images/social-media-facebook.png", "http://www.sutd.edu.sg/images/social-media-twitter.png", "http://www.sutd.edu.sg/images/social-media-youtube.png", "http://www.sutd.edu.sg/images/social-media-instagram.png", "http://www.sutd.edu.sg/cmsresource/Navigation_pic/iStock_000015771017XSmall.jpg", "http://www.sutd.edu.sg/cmsresource/Navigation_pic/DSC_0442.jpg", "http://www.sutd.edu.sg/cmsresource/Energy Innovation Challenge 2015_small.jpg", "http://www.sutd.edu.sg/cmsresource/yeo_kiat_seng71x71.jpg", "http://www.sutd.edu.sg/cmsresource/banner3.png", "http://www.sutd.edu.sg/cmsresource/banner2.png", "http://www.sutd.edu.sg/cmsresource/banner_homepage-20150811.png", "http://www.sutd.edu.sg/cmsresource/ad03.jpg", "//googleads.g.doubleclick.net/pagead/viewthroughconversion/1021803272/?value=0&guid=ON&script=0"]
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

        context "when website has paragraphs shorter than 20 characters" do
          it "should have an empty description" do
            response = double(body: File.open("#{File.dirname(__FILE__)}/../view/opengraph_no_meta_nor_description_short_p.html", 'r') { |f| f.read })
            RedirectFollower.stub(:new) { double(resolve: response) }
            og = OpenGraph.new("http://test.host/child_page")
            og.description.should == ""
          end
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
