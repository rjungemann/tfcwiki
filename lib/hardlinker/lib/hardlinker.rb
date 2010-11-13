class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

Dir.glob("#{File.dirname(__FILE__)}/linkers/*").each { |lib| require lib }

module TFCWiki
  class Sluggerizer
    def self.sluggerize string
      array = string.downcase.gsub(/[^\w]/, "_").gsub(/__+/, "_").split("")

      array = array[1..-1] while array.first == "_"
      array = array[0..-2] while array.last == "_"

      array.join("")
    end
  end
  
  module Linkers
    class Default
      def should_render? suffix = nil
        true
      end
      
      def render name, title, suffix, slug
        %{<a href="/#{slug}?name=#{name}">#{title}</a>}
      end
    end
  end
  
  class Hardlinker
    attr_accessor :linkers
    
    def initialize
      @linkers = []
      @wiki_link = /\[\[([^\[\]\|]+)(\|([^\[\]\|]+))?\]\]/
    end
    
    def header
      @linkers.find_all { |l| l.responds_to?(:header) }.collect { |l| l.header }.join("\n")
    end
    
    def render string
      string.gsub(@wiki_link) do |st|
        result = st.match @wiki_link
        name = result[1]
        title = result[3] ? result[3] : result[1]
        suffix = File.extname(title)[1..-1]
        slug = TFCWiki::Sluggerizer.sluggerize(suffix.blank? ? name : name[0..-(suffix.size)])
      
        linker = @linkers.find { |l| l.should_render? suffix }
      
        linker.render name, title, suffix, slug
      end
    end
  end
end