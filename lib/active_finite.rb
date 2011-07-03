require 'pathname'
require 'find'
require 'active_support/inflector'
require 'active_record'
require 'json'
require_relative 'master_table.rb'
require_relative 'get_table.rb'

def all_finite_tables
  MasterTable.all
end

def add_finites args
  modify_finite args do |vs, klass, column_name|
    if not klass.table_exists?
      ActiveRecord::Schema.define do
        create_table klass.table_name do |t|
          t.string column_name, :null => false
        end
        add_index klass.table_name, column_name, :unique => true
      end
    end
    MasterTable.add klass.table_name
    vs.each do |v|
      obj = klass.new
      obj.send column_name.to_s + '=', v
      obj.save
    end
  end
end

def delete_finites args
  delete_all = args[:values] == :all
  if delete_all
    args[:values] = []
  end
  modify_finite args do |vs, klass, column_name|
    MasterTable.add klass.table_name
    if delete_all
      klass.all.each do |o|
        klass.destroy o
      end
    else
      vs.each do |v|
        objs = klass.where column_name => v
        objs.each do |o|
          klass.destroy o
        end
      end
    end
    if klass.count.eql? 0
      ActiveRecord::Schema.define do
        drop_table klass.table_name
      end
      MasterTable.delete klass.table_name
      Object.send 'remove_const', klass.to_s.to_sym
    end
  end
end

def modify_finite args
  table_name = args[:in_table]
  if table_name.nil?
    raise 'A table name must be specified for :in_table.'
  end
  file_name   = args[:from_file] 
  values      = args[:values]
  column_name = args[:column_name] || default_column_name(table_name)
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

  klass = get_table table_name
  ActiveRecord::Base.transaction do
    yield to_be_modified, klass, column_name
  end
end

def default_column_name table_name
  table_name.to_s.singularize.to_sym
end

def as_class_name table_name
  table_name.to_s.singularize.capitalize.to_sym
end
