module TFCWiki
  module Linkers
    class OGV
      attr_accessor :prefix
      
      def initialize prefix = nil
        @prefix += "/" unless @prefix.blank?
      end
      
      def should_render? suffix = nil
        suffix == "ogv"
      end
      
      def render name, title, suffix, slug
        size = title.match(/size=(\w+)x(\w+)/)
        w, h = size[1], size[2]
        mp4 = title.match(/mp4=([\w\.-\\].mp4)/)[1]

        %{<video controls width="#{w}" height="#{h}">
  <source src="#{@prefix}#{name}" type="video/ogg"/>
  #{%{<source src="#{mp4}" type="video/mp4"/>\n} if mp4}
  <applet code="com.fluendo.player.Cortado.class" archive="players/cortado.jar" width="#{w}" height="#{h}">
    <param name="url" value="#{@prefix}#{name}"/> 
  </applet>
</video>}
      end
    end
  end 
end