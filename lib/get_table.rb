require 'external_includes'
require_relative 'as_class_name.rb'

def get_table sym, *args
  class_name = as_class_name sym
  class_not_defined = not(Object.const_defined? class_name)
  should_force = args.any? {|x| x == :force}
  if class_not_defined or should_force
    anon = Class.new ActiveRecord::Base
    Object.const_set class_name, anon
  else
    Object.const_get class_name
  end
end
