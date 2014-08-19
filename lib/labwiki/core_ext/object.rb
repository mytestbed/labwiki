class Object
  def try(method_name, *args)
    self.nil? ? self : self.send(method_name, *args)
  end
end
