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
  array = string.downcase.gsub(/[^\w]/, "_").gsub(/__+/, "_").split("")
  
  array = array[1..-1] while array.first == "_"
  array = array[0..-2] while array.last == "_"
  
  array.join("")
end

def time t
  days_of_week = %w[Sun Mon Tues Wed Thurs Fri Sat]
  day_of_week = t.strftime("%w")
  date = t.strftime("%m")
  date = date.chars.first == "0" ? date[1..-1] : date
  
  t.strftime("#{day_of_week}, #{date} %b %Y %H:%M:%d %Z")
end