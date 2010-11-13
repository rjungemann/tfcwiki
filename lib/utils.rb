class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

def time t
  t.strftime("%a, %m %b %Y %H:%M:%S %Z")
end