require 'sinatra/base'
require 'moneta'
require 'moneta/file'
require 'json'
require "#{File.dirname(__FILE__)}/lib/app"
require "#{File.dirname(__FILE__)}/lib/upload_app"

run Rack::URLMap.new({
  "/" => Rack::Cascade.new([
    TFCWiki::App.new,
    Rack::File.new("#{File.dirname(__FILE__)}/public")
  ]),
  "/uploads" => TFCWiki::UploadApp.new
})