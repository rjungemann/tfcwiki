require "#{File.dirname(__FILE__)}/utils"
require "#{File.dirname(__FILE__)}/hardlinker/lib/hardlinker"

module TFCWiki
  class App < Sinatra::Base
    configure do
      h = Hardlinker.new
    	h.linkers += [Linkers::Image.new, Linkers::Default.new]
      
      set :hardlinker, h
      set :db, Moneta::File.new(:path => "#{File.dirname(__FILE__)}/../db")
      
      db["posts"] ||= []
    end
    
    get "/" do
      @posts = options.db["posts"].collect { |slug|
        options.db["post-#{slug}"]
      }.reject { |post| !post["published"] }
      
      erb :"blog/index"
    end
    
    get "/feed.rss" do
      @blog_title = "tfcwiki"
    	@blog_img = "http://wiki.thefifthcircuit.com/splash.png"
    	@blog_link = "http://wiki.thefifthcircuit.com"
    	@blog_root = "http://wiki.thefifthcircuit.com"
      
      @title = ""
      @link = ""
      @description = ""
      @language = "en-us"
      @copyright = ""
      @docs = ""
      @last_build_data = Time.now
      @image_title = ""
      @image_url = ""
      @image_link = ""
      
      @posts = options.db["posts"].collect { |slug|
        options.db["post-#{slug}"]
      }.reject { |post| !post["published"] }
      
      erb :"blog/feed.rss"
    end
    
    get "/:slug" do
      slug = params[:slug]
      
      @post = options.db["post-#{slug}"]
      @name = params[:name] || (@post.blank? ? "" : @post["name"])
      
      @editable = @post ? false : true
      
      erb :"blog/post"
    end
    
    get "/:slug/edit" do
      slug = params[:slug]
      
      @post = options.db["post-#{slug}"]
      @editable = true
      
      erb :"blog/post"
    end
    
    get "/create" do
      @editable = true
      
      erb :"blog/post"
    end
    
    post("/:slug/edit") { create_or_update_post }
    post("/create") { create_or_update_post }
    
    post "/:slug/destroy" do
      slug = params[:slug]
      
      options.db["posts"] = options.db["posts"].reject do |slug|
        post["slug"] == slug
      end
      
      options.db["post-#{slug}"] = nil
      
      redirect "/"
    end
    
    private
    
    def create_or_update_post
      slug = params[:slug] || TFCWiki::Sluggerizer.sluggerize(params[:name])
      
      posts = options.db["posts"]
      post = options.db["post-#{slug}"] || { "created_on" => time(Time.now) }
      
      unless posts.include? slug
        posts << slug
        
        options.db["posts"] = posts
      end
      
      post["name"] = params[:name]
      post["slug"] = slug
      post["contents"] = params[:contents]
      post["parsed_contents"] = options.hardlinker.render(post["contents"])
      post["tags"] = params[:tags]
      post["parsed_tags"] = post["tags"].split(",").collect &:strip
      post["published"] = params[:published] == "on"
      post["created_on"] = time(Time.now)
      post["updated_on"] = time(Time.now)
      
      puts params[:published]
      
      options.db["post-#{slug}"] = post
      
      redirect "/#{slug}"
    end
  end
end