require "#{File.dirname(__FILE__)}/utils"
require "#{File.dirname(__FILE__)}/hardlinker/lib/hardlinker"

module TFCWiki
  class UploadApp < Sinatra::Base
    configure do
      db = Moneta::File.new(:path => "#{File.dirname(__FILE__)}/../db")
      upload_path = "#{File.dirname(__FILE__)}/../public/media"
      
      h = Hardlinker.new
    	h.linkers += [Linkers::Image.new, Linkers::Default.new]
      
      set :hardlinker, h
      set :upload_path, upload_path
      set :db, db
      
      `mkdir #{upload_path}` unless File.exists? upload_path
      
      db["uploads"] ||= []
    end
    
    get "/" do
      @uploads = options.db["uploads"].collect do |name|
        options.db["upload-#{name}"]
      end
      
      erb :"uploads/index"
    end
    
    get "/upload" do
      erb :"uploads/upload"
    end
    
    post "/upload" do
      @name = params[:alternative_name].blank? ?
        params[:file][:filename] : params[:alternative_name]
      
      raise "File already exists." if options.db["upload-#{@name}"]
      
      @file = params[:file][:tempfile]
      @description = params[:description]
      @parsed_description = TFCWiki::Sluggerizer.sluggerize(@description)
      @uploaded_on = time(Time.now)
      
      File.open("#{options.upload_path}/#{@name}", "w") do |f|
        f.puts @file.read
      end
      
      options.db["uploads"] = options.db["uploads"] << @name
      options.db["upload-#{@name}"] = {
        "name" => @name,
        "description" => @description,
        "parsed_description" => options.hardlinker.render(@description),
        "uploaded_on" => @uploaded_on
      }
      redirect "/uploads/"
    end
    
    post "/:name/destroy" do
      redirect "/uploads/"
    end
  end
end