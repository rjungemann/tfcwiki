require 'date'
require 'sinatra'
require 'redis'
require 'json'
require 'aws/s3'
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
    
    get "/wiki/?" do
      @posts = db.smembers("posts").collect { |slug|
        JSON.parse(db.get("post-#{slug}")) rescue nil
      }.reject { |post| !post["published"] }
      
      erb :"tfcwiki/index"
    end
    
    get "/wiki/feed.rss" do
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
      
      erb :"tfcwiki/feed.rss"
    end
    
    get "/wiki/:slug/?" do
      slug = params[:slug]
      
      @post = JSON.parse(db.get("post-#{slug}")) rescue nil
      @name = params[:name] || (@post.blank? ? "" : @post["name"])
      
      @editable = @post ? false : true
      
      erb :"tfcwiki/post"
    end
    
    get "/wiki/:slug/edit" do
      slug = params[:slug]
      
      @post = JSON.parse(db.get("post-#{slug}")) rescue nil
      @editable = true
      
      erb :"tfcwiki/post"
    end
    
    get "/wiki/create" do
      @editable = true
      
      erb :"tfcwiki/post"
    end
    
    post("/wiki/:slug/edit") { create_or_update_post }
    post("/wiki/create") { create_or_update_post }
    
    post "/wiki/:slug/destroy" do
      slug = params[:slug]
      
      db["posts"].collect {
        JSON.parse(db.get("post-#{slug}")) rescue nil
      }.each do |slug|
        db["posts"].srem(slug) if post["slug"] == slug
      end
      
      db.del("post-#{slug}")
      
      redirect "/wiki/"
    end
    
    private
    
    def db(options = {}); Redis.new(options) end
    
    def create_or_update_post
      if($turnstile)
        u = user
        
        "User isn't signed in." if u.blank?
        "User isn't authorized." if $turnstile.users.authorized? "vs", u[:name], "admin"
      end
      
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
      post["author"] = u[:name] unless u.blank?
      post["contents"] = params[:contents]
      post["parsed_contents"] = options.hardlinker.render(post["contents"])
      post["tags"] = params[:tags]
      post["parsed_tags"] = post["tags"].split(",").collect &:strip
      post["published"] = params[:published] == "on"
      post["updated_on"] = Time.now
      
      puts params[:published]
      
      db.set("post-#{slug}", post.to_json)
      
      redirect "/wiki/#{slug}"
    end
    
    def iphone?
      env["HTTP_USER_AGENT"] && env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
    end
    
    def user
      raise "You aren't currently signedin." if session[:uuid].blank?
      
      user = $turnstile.users.from_uuid session[:uuid]
      
      raise "Your login information expired. Please signin again." if user.nil?
      
      user
    end
  end
  
  class UploadApp < Sinatra::Base
    configure do
      upload_path = "#{File.dirname(__FILE__)}/../public/media"
      
      h = Hardlinker.new
    	h.linkers += [Linkers::Image.new, Linkers::Default.new]
      
      set :hardlinker, h
      set :upload_path, upload_path
      set :upload_type, :s3 # or :local
      
      `mkdir #{upload_path}` unless File.exists? upload_path
    end
    
    get "/wiki/uploads/" do
      @uploads = db.smembers("uploads").collect do |name|
        JSON.parse(db.get("upload-#{name}")) rescue nil
      end
      
      erb :"uploads/index"
    end
    
    get "/wiki/uploads/upload" do
      erb :"uploads/upload"
    end
    
    post "/wiki/uploads/upload" do
      @name = params[:alternative_name].blank? ?
        params[:file][:filename] : params[:alternative_name]
      
      file = JSON.parse(db.get("upload-#{@name}")) rescue nil
      
      raise "File already exists." unless file.blank?
      
      @file = params[:file][:tempfile]
      @description = params[:description]
      @parsed_description = TFCWiki::Sluggerizer.sluggerize(@description)
      @uploaded_on = Time.now
      
      if(options.upload_type == :s3)
        AWS::S3::Base.establish_connection!(
          :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
        )
        AWS::S3::S3Object.store(@name, @file, ENV["TFCWIKIBUCKET"], :access => :public_read)
      else
        File.open("#{options.upload_path}/#{@name}", "w") do |f|
          f.puts @file.read
        end
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
      redirect "/wiki/uploads/"
    end
    
    get '/wiki/uploads/:name' do
      if options.upload_type == :s3
        redirect "http://#{ENV["TFCWIKIBUCKET"]}.s3.amazonaws.com/#{params[:name]}"
      else
        File.open("#{options.upload_path}/#{name}")
      end
    end
    
    post "/wiki/uploads/:name/destroy" do
      redirect "/wiki/uploads/"
    end
    
    private
    
    def db(options = {}); Redis.new(options) end
    
    def iphone?
      env["HTTP_USER_AGENT"] && env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/]
    end
  end
end