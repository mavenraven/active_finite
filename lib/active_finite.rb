require 'pathname'
require 'find'
require 'active_support/inflector'
require 'active_record'
require 'json'

def active_finite sym
  anon = Class.new ActiveRecord::Base
  klass = Object.const_set(sym.to_s.singularize.capitalize, anon)
  klass
end

def create_finite args
  modify_finite args do |vs, klass, column_name|
    vs.each do |v|
      obj = klass.new
      obj.send column_name.to_s + '=', v
      obj.save
    end
  end
end

def drop_finite args
  modify_finite args do |vs, klass, column_name|
    vs.each do |v|
      objs = klass.where column_name => v
      objs.each do |o|
        klass.destroy o
      end
    end
  end
end

def modify_finite args
  table_name = args[:in_table]
  if table_name.nil?
    raise 'A table name must be specified for :in_table .'
  end
  file_name   = args[:from_file] 
  values      = args[:values]
  column_name = args[:column_name] || :value
  if values.nil? and file_name.nil?
    raise 'Either :from_file or :values must be specified.'
  end

  to_be_modified = Array.new
  if not values.nil?
    to_be_modified = to_be_modified.concat values
  end

  if not file_name.nil?
    to_be_modified = to_be_modified.concat JSON.load open file_name
  end

  klass = active_finite table_name
  yield to_be_modified, klass, column_name
end

def default_column_name
  :value
end
