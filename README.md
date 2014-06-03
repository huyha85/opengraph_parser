# OpengraphParser

OpengraphParser is a simple Ruby library for parsing Open Graph protocol information from a website. Learn more about the protocol at:
http://ogp.me

## Installation

```bash
  gem install opengraph_parser
```

or add to Gemfile

```bash
  gem "opengraph_parser"
```

## Usage

### Parsing an URL

```ruby
og = OpenGraph.new("http://ogp.me")
og.title # => "Open Graph protocol"
og.type # => "website"
og.url # => "http://ogp.me/"
og.description # => "The Open Graph protocol enables any web page to become a rich object in a social graph."
og.images # => ["http://ogp.me/logo.png"]
```

You can also get other Open Graph metadata as:

```ruby
og.metadata # => {"og:image:type"=>"image/png", "og:image:width"=>"300", "og:image:height"=>"300"}
```

### Parsing a HTML document

```ruby
og = OpenGraph.new(html_string)
```

### Custom header fields
In some cases you may need to change fields in HTTP request header for an URL
```ruby
og = OpenGraph.new("http://opg.me", { :headers => {'User-Agent' => 'Custom User Agent'} })
```

### Fallback
If you try to parse Open Graph information for a website that doesn’t have any Open Graph metadata, the library will try to find other information in the website as the following rules:

  <title> for title
  <meta name="description"> for description
  <link rel="image_src"> or all <img> tags for images

You can disable this fallback lookup by passing false to init method:

```ruby
og = OpenGraph.new("http://ogp.me", false)
```

## Contributing to opengraph_parser

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Huy Ha. See LICENSE.txt for further details.
