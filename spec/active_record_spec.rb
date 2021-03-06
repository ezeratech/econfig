require "active_record"

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

ActiveRecord::Base.connection.create_table :econfig_options do |t|
  t.string :key, :null => false
  t.string :value
end

require "econfig/active_record"

describe Econfig::ActiveRecord do
  let(:backend) { Econfig::ActiveRecord.new }
  around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  describe "#keys" do
    it "returns a list of set keys" do
      backend.set("foo", "123")
      backend.set("bar", "664")
      backend.keys.should eq(Set.new(["foo", "bar"]))
    end
  end

  describe '#has_key?' do
    it 'returns true if there is a config item with the given key' do
      backend.set('foo', '123')
      backend.has_key?('foo').should eq(true)
    end
    it 'returns false if there is no config item with the given key' do
      backend.has_key?('bar').should eq(false)
    end
  end

  describe "#get" do
    it "fetches a previously set option" do
      backend.set("foo", "bar")
      backend.get("foo").should == "bar"
    end

    it "fetches a previously persisted option" do
      Econfig::ActiveRecord::Option.create!(:key => "foo", :value => "bar")
      backend.get("foo").should == "bar"
    end

    it "returns nil if option is not set" do
      backend.get("foo").should be_nil
    end

    it "yields if option is not set" do
      backend.get("foo") { "blah" }.should eq("blah")
    end

    it "ignores block if set" do
      backend.set("foo", "bar")
      backend.get("foo") { raise "blah" }.should eq("bar")
    end
  end

  describe "#set" do
    it "persists keys to database" do
      backend.set("foo", "bar")
      Econfig::ActiveRecord::Option.find_by_key!("foo").value.should == "bar"
    end
  end
end
