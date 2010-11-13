module TFCWiki
  module Linkers
    class Image
      attr_accessor :prefix
      
      def initialize prefix = nil
        @prefix += "/" unless @prefix.blank?
      end
      
      def header
        %{<script src="scripts/facebox.js"></script>}
      end
      
      def should_render? suffix = nil
        %w[jpg jpeg gif png svg].include? suffix
      end
      
      def render name, title, suffix, slug
        %{<img src="#{@prefix}#{name}" class="upload image-upload #{slug}" alt="#{title}">}
      end
    end
  end
end