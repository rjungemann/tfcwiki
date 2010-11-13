module TFCWiki
  module Linkers
    class MP4
      attr_accessor :prefix
      
      def initialize prefix = nil
        @prefix += "/" unless @prefix.blank?
      end
      
      def should_render? suffix = nil
        suffix == "mp4"
      end
      
      def render name, title, suffix, slug
        size = title.match(/size=(\w+)x(\w+)/)
        w, h = size[1], size[2]
        
        %{<video controls>
  <source src="#{@prefix}#{name}" type="video/mp4"/>
</video>}
      end
    end
  end 
end