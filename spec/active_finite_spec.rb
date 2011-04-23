require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def reconnect
  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    :database => ':memory:',
    :pool     => 5,
    :timeout  => 5000)
end

describe 'get_table' do
  before :each do
    reconnect
  end
  it 'returns a class that is a child of active record base' do
    get_table(:test).superclass.should eql ActiveRecord::Base
  end
  it 'brings a class into scope' do
    get_table :spaces
    Object.const_defined?(:Space).should be true
  end
  it 'will not redefine a previously defined constant' do
    Define = true
    get_table :defines
    Define.should == true
  end
  it 'will redefine a previously defined constant with the force option' do
    Anyway = true
    get_table :anyways, :force
    Anyway.should_not == true
  end
end

describe 'all_finite_tables' do
  before :each do
    reconnect
  end
  it 'returns all active record classes created by active_finite' do
    add_finites in_table: :things, values: ['1']
    add_finites in_table: :stuffs, values: ['s']
    all_finite_tables.should == [Thing, Stuff]
  end
  it 'will no longer return a removed finite table' do
    add_finites in_table: :things, values: ['1']
    delete_finites in_table: :things, values: ['1']
    all_finite_tables.should == []
  end
  it 'returns a table that was used with add_finites' do
    ActiveRecord::Schema.define do
      create_table :things do |t|
        t.string :column, :null => false
      end
    end
    add_finites in_table: :things,
                column_name: :column,
                values: ['1']

    all_finite_tables.should == [Thing]
  end
  it 'returns a table that was used with delete_finites' do
    ActiveRecord::Schema.define do
      create_table :things do |t|
        t.string :column, :null => false
      end
    end
    t = Thing.new 
    t.column = "hi"
    t.save

    u = Thing.new
    u.column = "bye"
    u.save
    
    delete_finites in_table: :things,
                   column_name: :column,
                   values: ["bye"]

    all_finite_tables.should == [Thing]
  end
end

describe 'as_class_name' do
  it 'capitalizes its input' do
    as_class_name(:as).should eql :A
  end
  it 'properly singularizes its input' do
    as_class_name(:users).should eql :User
    as_class_name(:foxes).should eql :Fox
    as_class_name(:sheep).should eql :Sheep
  end
end

describe 'add_finites' do
  before :each do
    reconnect
  end
  it 'adds finites as rows to the database' do
    finites = ['red', 'blue', 'green']
    add_finites in_table: :colors, values: finites

    finites.each do |f|
      Color.where(default_column_name => f).should_not nil
    end
  end

  it 'creates the coresponding table if it doesn\`t exist' do
    add_finites in_table: :tests, values: [1]
    Object.const_defined?(:Test).should be true
  end

  it 'can use a different column name' do
    finites = ['mickey', 'donald', 'scrooge']
    add_finites in_table: :characters, 
      values: finites, 
      column_name: :column_name

    finites.each do |f|
      Color.where(:column_name => f).should_not nil
    end
  end

  it 'can load from a json file' do
    file_path = File.expand_path(File.dirname(__FILE__) + '/villans.json')
    add_finites in_table: :villans,
      from_file: file_path

    ['scaramanga', 'no', 'janus'].each do |v|
      Villan.where(default_column_name => v).should_not nil
    end
  end

  it 'will fail atomically' do
    begin
      add_finites in_table: :wu_members, values: ['rza', 'gza', nil]
    rescue
      ['rza', 'gza'].each do |w|
        get_table(:wu_members).where(default_column_name => w).should nil
      end
    end
  end
  it 'will not add a duplicate value' do
    lambda do
      add_finites(in_table: :numbers, values: ['1','1'])
    end.should raise_error ActiveRecord::RecordNotUnique
  end
end

describe 'delete_finites' do
  before :each do
    reconnect
  end

  it 'can delete previously added finites' do
    add_finites in_table: :adjs, values: ['delete', 'drop']
    delete_finites in_table: :adjs, values: ['delete']
    Adj.where(default_column_name => 'delete').should nil
    Adj.where(default_column_name => 'drop').should_not nil
  end

  it 'will remove the table if there are no finites left' do
    add_finites in_table: :deletes, values: ['delete']
    delete_finites in_table: :deletes, values: ['delete']
    Object.const_defined?(:Delete).should_not be true
  end

  it 'can delete all values with the all option' do
    add_finites in_table: :adjs, values: ['delete', 'drop']
    delete_finites in_table: :adjs, values: :all
    Object.const_defined?(:Adj).should_not be true
  end
end

