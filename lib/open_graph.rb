require 'nokogiri'
require 'redirect_follower'
require "addressable/uri"

class OpenGraph
  attr_accessor :src, :url, :type, :title, :description, :images, :metadata, :response

  def initialize(src, fallback = true)
    @src = src
    @images = []
    @metadata = {}
    parse_opengraph
    load_fallback if fallback
    check_images_path
  end

  private
  def parse_opengraph
    begin
      @response = RedirectFollower.new(@src).resolve
    rescue
      @title = @url = @src
      return
    end

    if @response && @response.body
      attrs_list = %w(title url type description)
      doc = Nokogiri.parse(@response.body)
      doc.css('meta').each do |m|
        if m.attribute('property') && m.attribute('property').to_s.match(/^og:(.+)$/i)
          m_content = m.attribute('content').to_s.strip
          case metadata_name = m.attribute('property').to_s.gsub("og:", "")
            when *attrs_list
              self.instance_variable_set("@#{metadata_name}", m_content) unless m_content.empty?
            when "image"
              add_image(m_content)
            else
              @metadata[m.attribute('property').to_s] = m_content
          end
        end
      end
    end
  end

  def load_fallback
    if @response && @response.body
      doc = Nokogiri.parse(@response.body)

      if @title.to_s.empty? && doc.xpath("//head/title").size > 0
        @title = doc.xpath("//head/title").first.text.to_s.strip
      end

      @url = @src if @url.to_s.empty?

      if @description.to_s.empty? && description_meta = doc.xpath("//head/meta[@name='description']").first
        @description = description_meta.attribute("content").to_s.strip
      end

      fetch_images(doc, "//head/link[@rel='image_src']", "href") if @images.empty?
      fetch_images(doc, "//img", "src") if @images.empty?
    end
  end

  def check_images_path
    uri = Addressable::URI.parse(@src)
    imgs = @images.dup
    @images = []
    imgs.each do |img|
      if Addressable::URI.parse(img).host.nil?
        full_path = generate_path(img, uri)
        add_image(full_path)
      else
        add_image(img)
      end
    end
  end

  def add_image(image_url)
    @images << image_url unless @images.include?(image_url) || image_url.to_s.empty?
  end

  def fetch_images(doc, xpath_str, attr)
    doc.xpath(xpath_str).each do |link|
      add_image(link.attribute(attr).to_s.strip)
    end
  end

  def generate_path(relative_path, uri)
    host = "#{uri.scheme}://#{uri.host}#{':' + uri.port.to_s if uri.port}"
    if relative_path.start_with?('/')
      "#{host}#{relative_path}"
    elsif uri.path.to_s.end_with?('/')
      "#{host}#{uri.path}#{relative_path}"
    else
      "#{host}#{uri.path}/#{relative_path}"
    end
  end
end