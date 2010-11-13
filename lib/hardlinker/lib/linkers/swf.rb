module TFCWiki
  module Linkers
    class SWF
      attr_accessor :prefix
      
      def initialize prefix = nil
        @prefix += "/" unless @prefix.blank?
      end
      
      def header
        %{<script src="scripts/swfobject.js"></script>}
      end
      
      def should_render? suffix = nil
        suffix == "swf"
      end
      
      def render name, title, suffix, slug
        size = title.match(/size=(\w+)x(\w+)/)
        w, h = size[1], size[2]

        %{<div id="flashcontent"></div> 

<script type="text/javascript">
  var so = new SWFObject('#{@prefix}#{name}', 'mpl', '#{w}', '#{h}', '9');

  so.addParam('allowfullscreen', 'true');
  so.write('flashcontent');
</script>}
      end
    end
  end 
end