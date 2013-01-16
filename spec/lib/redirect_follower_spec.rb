require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RedirectFollower do
  describe "#resolve" do
    let(:url) { "http://test.host" }
    let(:https_url) { "https://test.host" }
    let(:mock_res) { double(body: "Body is here.") }
    let(:mock_redirect) {
      m = double(body: %Q{<body><a href="http://new.test.host"></a></body>}, kind_of?: Net::HTTPRedirection)
      m.stub(:[]).and_return(nil)
      m
    }

    context "with no redirection" do
      it "should return the response" do
        Net::HTTP.should_receive(:get_response).and_return(mock_res)

        res = RedirectFollower.new(url).resolve
        res.body.should == "Body is here."
        res.redirect_limit.should == 5
      end

      describe "and uri scheme is HTTPS" do
        it "should use https method to retrieve the uri" do
          uri = URI.parse(URI.escape(https_url))

          https = Net::HTTP.new(uri.host, 443)
          Net::HTTP.should_receive(:new).with(uri.host, 443).and_return(https)
          https.should_receive(:request_get).and_return(mock_res)

          res = RedirectFollower.new(https_url).resolve
          res.body.should == "Body is here."
          res.redirect_limit.should == 5
        end
      end
    end

    context "with redirection" do
      it "should follow the link in redirection" do
        Net::HTTP.should_receive(:get_response).with(URI.parse(URI.escape(url))).and_return(mock_redirect)
        Net::HTTP.should_receive(:get_response).with(URI.parse(URI.escape("http://new.test.host"))).and_return(mock_res)

        res = RedirectFollower.new(url).resolve
        res.body.should == "Body is here."
        res.redirect_limit.should == 4
      end
    end

    context "with unlimited redirection" do
      it "should raise TooManyRedirects error" do
        Net::HTTP.stub(:get_response).and_return(mock_redirect)
        lambda {
          RedirectFollower.new(url).resolve
        }.should raise_error(RedirectFollower::TooManyRedirects)
      end
    end
  end
end