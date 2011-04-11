require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:',
  :pool     => 5,
  :timeout  => 5000)

  describe 'active_finite' do
    it 'returns a class that is a child of active record base' do
      active_finite(:test).superclass.should eql ActiveRecord::Base
    end
    it 'properly singularizes its classes' do
      active_finite(:users).should eql User
      active_finite(:foxes).should eql Fox
      active_finite(:sheep).should eql Sheep
    end
  end

  describe 'create_finite' do
    it 'adds finites as rows to the database' do
      ActiveRecord::Schema.define do
        create_table :colors do |t|
          t.string default_column_name, :null => false
        end
      end
      finites = ['red', 'blue', 'green']
      create_finite in_table: :colors, values: finites

      finites.each do |f|
        Color. where(default_column_name => f).should_not nil
      end
    end

    it 'can change the column name' do
      ActiveRecord::Schema.define do
        create_table :characters do |t|
          t.string :column_name, :null => false
        end
      end
      finites = ['mickey', 'donald', 'scrooge']

      create_finite in_table: :characters, 
        values: finites, 
        column_name: :column_name

      finites.each do |f|
        Color.where(:column_name => f).should_not nil
      end
    end

    it 'can load from a json file' do
      ActiveRecord::Schema.define do
        create_table :villans do |t|
          t.string default_column_name, :null => false
        end
      end
      file_path = File.expand_path(File.dirname(__FILE__) + '/villans.json')
      create_finite in_table: :villans,
        from_file: file_path

      ['scaramanga', 'no', 'janus'].each do |v|
        Villan.where(default_column_name => v).should_not nil
      end
    end
  end

  describe 'drop_finite' do
    it 'can delete previously added finites' do
      ActiveRecord::Schema.define do
        create_table :adjs do |t|
          t.string default_column_name, :null => false
        end

        create_finite in_table: :adj, values: ['delete', 'drop']
        drop_finite in_table: :adj, values: ['delete']
        Adj.where(default_column_name => 'delete').should nil
        Adj.where(default_column_name => 'drop').should_not nil
      end
    end
  end

