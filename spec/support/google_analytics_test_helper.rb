module GoogleAnalyticsTestHelper
  def stub_generic_ga_request
    stub_request(:post, 'http://www.google-analytics.com/collect')
        .to_return(status: 200, body: '', headers: {})
  end

  def stub_first_published_at_ga_request(edition)
    stub_request(:post, 'http://www.google-analytics.com/collect').
        with(body: { 'v': '1', 'tid': 'UA-26179049-1', 'cid': '660ad712-9753-4cb9-97a7-c9e9f13c318e', 't': 'event', 'cd90': edition.first_published_at },
             headers: { 'Accept': '*/*', 'Accept-Encoding': 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type': 'application/x-www-form-urlencoded', 'Host': 'www.google-analytics.com', 'User-Agent': 'Ruby' }).
        to_return(status: 200, body: '', headers: {})
  end
end
