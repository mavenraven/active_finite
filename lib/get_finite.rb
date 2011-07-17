require 'external_includes'
require_relative 'as_class_name.rb'
require_relative 'get_finite.rb'

def get_finite sym, *args
  class_name = as_class_name sym
  class_not_defined = not(Object.const_defined? class_name)
  should_force = args.any? {|x| x == :force}
  if class_not_defined or should_force
    anon = Class.new ActiveRecord::Base
    Object.const_set class_name, anon
  else
    anon = Object.const_get class_name
  end
  if anon.respond_to? :table_exists? and anon.table_exists?
    anon.class_eval do
      method_name = anon.send(:new).attributes.keys[0]
      define_method(:get_value) do
        self.send method_name
      end
      define_method(:set_with_existing_value) do |value|
        result = anon.send 'find_by_' + method_name + '!', value 
        self.send anon.primary_key + '=', result.send(anon.primary_key)
        self.send method_name + '=', result.send(method_name)
      end
    end
  end
  anon
end

