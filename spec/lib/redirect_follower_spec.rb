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
        uri = URI.parse(URI.escape(url))
        http = Net::HTTP.new(uri.host)
        Net::HTTP.should_receive(:new).with(uri.host, uri.port).and_return(http)
        http.should_receive(:request_get).and_return(mock_res)

        res = RedirectFollower.new(url).resolve
        res.body.should == "Body is here."
        res.redirect_limit.should == 5
      end

      it "should respect headers" do
        uri = URI.parse(URI.escape(url))
        http = Net::HTTP.new(uri.host)
        headers = {'User-Agent' => 'RSPEC'}
        Net::HTTP.should_receive(:new).with(uri.host, uri.port).and_return(http)
        http.should_receive(:request_get).with(uri.request_uri, headers).and_return(mock_res)

        res = RedirectFollower.new(url, :headers => headers).resolve
        
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
        uri = URI.parse(URI.escape(url))
        uri2 = URI.parse(URI.escape("http://new.test.host"))
        http = Net::HTTP.new(uri.host)
        http2 = Net::HTTP.new(uri2.host)
        Net::HTTP.should_receive(:new).ordered.with(uri.host, uri.port).and_return(http)
        Net::HTTP.should_receive(:new).ordered.with(uri2.host, uri2.port).and_return(http2)

        http.should_receive(:request_get).with(uri.request_uri, anything).and_return(mock_redirect)

        http2.should_receive(:request_get).with(uri.request_uri, anything).and_return(mock_res)

        res = RedirectFollower.new(url).resolve
        res.body.should == "Body is here."
        res.redirect_limit.should == 4
      end
    end

    context "with unlimited redirection" do
      it "should raise TooManyRedirects error" do
        uri = URI.parse(URI.escape(url))
        http = Net::HTTP.new uri.host
        http.stub(:request_get).and_return(mock_redirect)
        Net::HTTP.stub(:new).and_return(http)
        lambda {
          RedirectFollower.new(url).resolve
        }.should raise_error(RedirectFollower::TooManyRedirects)
      end
    end
  end
end
