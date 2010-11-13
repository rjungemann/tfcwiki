require 'sinatra/base'
require "#{::File.dirname(__FILE__)}/lib/tfcwiki"

run Rack::URLMap.new({
  "/" => Rack::Cascade.new([
    TFCWiki::App.new,
    Rack::File.new("#{::File.dirname(__FILE__)}/public")
  ]),
  "/uploads" => TFCWiki::UploadApp.new
})