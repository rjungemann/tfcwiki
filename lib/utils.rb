class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

def parse_links string
  wiki_link = /\[\[([^\[\]\|]+)(\|([^\[\]\|]+))?\]\]/
  
  string.gsub(wiki_link) do |st|
    result = st.match wiki_link
    name = result[1]
    title = result[3] ? result[3] : result[1]
    extname = File.extname(title)
    slug = sluggerize(extname.blank? ? title : title[0..-(extname.size + 1)])

    if %w[jpg jpeg gif png svg].include?(extname[1..-1])
      %{<img src="media/#{name}" class="upload image-upload #{slug}" alt="#{title}">}
    else
      %{<a href="/#{slug}?name='#{title}'">#{name}</a>}
    end
  end
end

# converts a string into a strictly lowercase string with underscores
# replacing any non alphanumeric characters. Underscores are removed from the
# beginning and end, and two or more adjacent underscores are reduced to one.
def sluggerize string
  str = string.downcase.gsub(/[^\w]/, "_").gsub(/__+/, "_")
  
  str = str[1..-1] while str[0] == "_"
  str = str[0..-2] while str[-1] == "_"
  
  str
end

def time t
  t.strftime("%a, %m %b %Y %H:%M:%S %Z")
end