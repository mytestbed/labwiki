class Object
  def try(method_name)
    self.nil? ? self : self.send(method_name)
  end
end
