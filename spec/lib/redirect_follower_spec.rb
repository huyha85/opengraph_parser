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

    context "with redirect_limit in options hash" do
      it "should update redirect_limit" do
        rf = RedirectFollower.new(url, redirect_limit: 20)
        rf.redirect_limit.should == 20
      end
    end

    context "with no redirection" do
      it "should return the response" do
        uri = URI.parse(URI.escape(url))

        http = Net::HTTP.new(uri.host, uri.port)
        Net::HTTP.should_receive(:new).with(uri.host, uri.port).and_return(http)
        http.should_receive(:request_get).and_return(mock_res)

        res = RedirectFollower.new(url).resolve
        res.body.should == "Body is here."
        res.redirect_limit.should == RedirectFollower::REDIRECT_DEFAULT_LIMIT
      end

      describe "and uri scheme is HTTPS" do
        it "should use https method to retrieve the uri" do
          uri = URI.parse(URI.escape(https_url))

          https = Net::HTTP.new(uri.host, uri.port)
          Net::HTTP.should_receive(:new).with(uri.host, uri.port).and_return(https)
          https.should_receive(:request_get).and_return(mock_res)

          res = RedirectFollower.new(https_url).resolve
          res.body.should == "Body is here."
          res.redirect_limit.should == RedirectFollower::REDIRECT_DEFAULT_LIMIT
        end
      end

      describe "and has headers option" do
        it "should add headers when retrieve the uri" do
          uri = URI.parse(URI.escape(url))

          http = Net::HTTP.new(uri.host, uri.port)
          Net::HTTP.should_receive(:new).with(uri.host, uri.port).and_return(http)
          http.should_receive(:request_get).and_return(mock_res)
          res = RedirectFollower.new(url, {:headers => {'User-Agent' => 'My Custom User-Agent'}}).resolve
          res.body.should == "Body is here."
          res.redirect_limit.should == RedirectFollower::REDIRECT_DEFAULT_LIMIT
        end
      end
    end

    context "with redirection" do
      it "should follow the link in redirection" do
        uri = URI.parse(URI.escape(url))

        http = Net::HTTP.new(uri.host, uri.port)
        Net::HTTP.should_receive(:new).twice.and_return(http)
        http.should_receive(:request_get).twice.and_return(mock_redirect, mock_res)

        res = RedirectFollower.new(url).resolve
        res.body.should == "Body is here."
        res.redirect_limit.should == RedirectFollower::REDIRECT_DEFAULT_LIMIT - 1
      end
    end

    context "with unlimited redirection" do
      it "should raise TooManyRedirects error" do
        uri = URI.parse(URI.escape(url))

        http = Net::HTTP.new(uri.host, uri.port)
        Net::HTTP.stub(:new).and_return(http)
        http.stub(:request_get).and_return(mock_redirect)

        lambda {
          RedirectFollower.new(url).resolve
        }.should raise_error(RedirectFollower::TooManyRedirects)
      end
    end
  end
end
