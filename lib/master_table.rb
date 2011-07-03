require_relative 'get_table.rb'
require_relative 'external_includes.rb'

module MasterTable
  def self.table_name
    :active_finites
  end
  def self.column_name
    default_column_name self.table_name
  end
  def self.table
    get_table self.table_name
  end
  def self.all
    if self.table.table_exists?
      self.table
      .all
      .collect {|x| x.send self.column_name.to_s}
      .collect {|x| get_table x}
    else
      []
    end
  end
  def self.add table_name
    if not self.table.table_exists?
      ActiveRecord::Schema.define do
        create_table MasterTable.table_name do |t|
          t.string MasterTable.column_name, :null => false
        end
        add_index MasterTable.table_name, MasterTable.column_name, :unique => true
      end
    end
    if self.table.where(self.column_name => table_name).empty?
      new_finite = self.table.new
      new_finite.send self.column_name.to_s + '=', table_name
      new_finite.save
    end
  end
  def self.delete table_name
    matches = self.table.where self.column_name => table_name
    matches.each do |m|
      self.table.destroy m
    end
    if self.table.count.eql? 0
      ActiveRecord::Schema.define do
        drop_table MasterTable.table_name
      end
    end
  end
end
