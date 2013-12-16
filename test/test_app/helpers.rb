
class String
  # simplified version of rails', only get asdf_gfre from AsdfGfre
  def underscore
    word = dup
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
  end
end
