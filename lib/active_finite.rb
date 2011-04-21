require 'pathname'
require 'find'
require 'active_support/inflector'
require 'active_record'
require 'json'

def get_finite_table sym, *args
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

def as_class_name table_name
  table_name.to_s.singularize.capitalize.to_sym
end

def all_finite_tables
  master = get_finite_table(master_table_name)
  if master.table_exists?
    master
    .where("#{default_column_name} != ?", master_table_name)
    .collect {|x| x.send default_column_name.to_s}
    .collect {|x| get_finite_table x}
  else
    []
  end
end

def master_table_name
  :active_finites
end

def add_to_master table_name
  add_finites in_table: master_table_name, values: [table_name]
end

def delete_from_master table_name
  delete_finites in_table: master_table_name, values: [table_name]
end

def is_in_master_table? table_name
  if table_name.eql? master_table_name
    true
  else
    get_finite_table(master_table_name)
    .where("#{default_column_name} != ?", master_table_name)
    .where("#{default_column_name} == ?", table_name)
    .any?
  end
end


def add_finites args
  modify_finite args do |vs, klass, column_name|
    if not klass.table_exists?
      ActiveRecord::Schema.define do
        create_table klass.table_name do |t|
          t.string column_name, :null => false
        end
      end
      add_to_master klass.table_name
    end
    vs.each do |v|
      obj = klass.new
      obj.send column_name.to_s + '=', v
      obj.save
    end
  end
end

def delete_finites args,
  delete_all = args[:values] == :all
  if delete_all
    args[:values] = []
  end
  modify_finite args do |vs, klass, column_name|
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
      delete_from_master klass.table_name
      Object.send 'remove_const', klass.to_s.to_sym
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

  klass = get_finite_table table_name
  ActiveRecord::Base.transaction do
    yield to_be_modified, klass, column_name
  end
end

def default_column_name
  :value
end
