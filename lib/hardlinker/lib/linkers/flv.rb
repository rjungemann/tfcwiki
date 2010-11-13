module TFCWiki
  module Linkers
    class FLV
      attr_accessor :prefix
      
      def initialize prefix = nil
        @prefix += "/" unless @prefix.blank?
      end
      
      def should_render? suffix = nil
        suffix == "flv"
      end
      
      def render name, title, suffix, slug
        size = title.match(/size=(\w+)x(\w+)/)
        w, h = size[1], size[2]
    
        %{<div id="flashcontent"></div> 
    
<script type="text/javascript">
  var so = new SWFObject('players/player.swf', 'mpl', '#{w}', '#{h}', '9');

  so.addParam('allowfullscreen', 'true');
  so.addParam('flashvars', 'file=#{@prefix}#{name}&autostart=true');
  so.write('flashcontent');
</script>}
      end
    end
  end
end