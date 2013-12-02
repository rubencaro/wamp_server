class String
  def constantize
    names = self.split('::')
    names.shift if names.empty? || names.first.empty?

    constant = Object
    names.each do |name|
      constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
    end
    constant
  end

  # only get AsdfGfre from asdf_gfre
  def camelize
    self.split('_').map {|w| w.capitalize}.join
  end

  # simplified version of rails', only get asdf_gfre from AsdfGfre
  def underscore
    word = dup
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
  end

  def classify
    self.camelize
  end
end
