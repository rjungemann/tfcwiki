require 'date'
require 'redis'
require 'json'
require "#{File.dirname(__FILE__)}/hardlinker/lib/hardlinker"

class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

module TFCWiki
  class App < Sinatra::Base
    configure do
      h = Hardlinker.new
    	h.linkers += [Linkers::Image.new, Linkers::Default.new]
      
      set :hardlinker, h
    end
    
    get "/" do
      @posts = db.smembers("posts").collect { |slug|
        JSON.parse(db.get("post-#{slug}")) rescue nil
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
      
      @posts = db.smembers("posts").collect { |slug|
        JSON.parse(db.get("post-#{slug}")) rescue nil
      }.reject { |post| !post["published"] }
      
      erb :"blog/feed.rss"
    end
    
    get "/:slug" do
      slug = params[:slug]
      
      @post = JSON.parse(db.get("post-#{slug}")) rescue nil
      @name = params[:name] || (@post.blank? ? "" : @post["name"])
      
      @editable = @post ? false : true
      
      erb :"blog/post"
    end
    
    get "/:slug/" do
      redirect "/#{params[:slug]}"
    end
    
    get "/:slug/edit" do
      slug = params[:slug]
      
      @post = JSON.parse(db.get("post-#{slug}")) rescue nil
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
      
      db["posts"].collect {
        JSON.parse(db.get("post-#{slug}")) rescue nil
      }.each do |slug|
        db["posts"].srem(slug) if post["slug"] == slug
      end
      
      db.del("post-#{slug}")
      
      redirect "/"
    end
    
    private
    
    def db(options = {}); Redis.new(options) end
    
    def create_or_update_post
      slug = params[:slug] || TFCWiki::Sluggerizer.sluggerize(params[:name])
      
      posts = db.smembers("posts")
      
      post = begin
        JSON.parse(db.get("post-#{slug}"))
      rescue
        { "created_on" => Time.now }
      end
      
      db.sadd("posts", slug) unless db.sismember("posts", slug)
      
      post["name"] = params[:name]
      post["slug"] = slug
      post["contents"] = params[:contents]
      post["parsed_contents"] = options.hardlinker.render(post["contents"])
      post["tags"] = params[:tags]
      post["parsed_tags"] = post["tags"].split(",").collect &:strip
      post["published"] = params[:published] == "on"
      post["updated_on"] = Time.now
      
      puts params[:published]
      
      db.set("post-#{slug}", post.to_json)
      
      redirect "/#{slug}"
    end
  end
  
  class UploadApp < Sinatra::Base
    configure do
      upload_path = "#{File.dirname(__FILE__)}/../public/media"
      
      h = Hardlinker.new
    	h.linkers += [Linkers::Image.new, Linkers::Default.new]
      
      set :hardlinker, h
      set :upload_path, upload_path
      
      `mkdir #{upload_path}` unless File.exists? upload_path
    end
    
    get "/" do
      @uploads = db.smembers("uploads").collect do |name|
        JSON.parse(db.get("upload-#{name}")) rescue nil
      end
      
      require 'pp'; pp @uploads
      
      erb :"uploads/index"
    end
    
    get "/upload" do
      erb :"uploads/upload"
    end
    
    post "/upload" do
      @name = params[:alternative_name].blank? ?
        params[:file][:filename] : params[:alternative_name]
      
      file = JSON.parse(db.get("upload-#{@name}")) rescue nil
      
      raise "File already exists." unless file.blank?
      
      @file = params[:file][:tempfile]
      @description = params[:description]
      @parsed_description = TFCWiki::Sluggerizer.sluggerize(@description)
      @uploaded_on = Time.now
      
      File.open("#{options.upload_path}/#{@name}", "w") do |f|
        f.puts @file.read
      end
      
      db.sadd("uploads", @name)
      db.set(
        "upload-#{@name}",
        {
          "name" => @name,
          "description" => @description,
          "parsed_description" => options.hardlinker.render(@description),
          "uploaded_on" => @uploaded_on
        }.to_json
      )
      redirect "/uploads/"
    end
    
    post "/:name/destroy" do
      redirect "/uploads/"
    end
    
    private
    
    def db(options = {}); Redis.new(options) end
  end
end