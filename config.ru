require 'sinatra/base'
require "#{::File.dirname(__FILE__)}/lib/tfcwiki"

run Rack::URLMap.new({
  "/" => TFCWiki::App.new,
  "/uploads" => TFCWiki::UploadApp.new
})