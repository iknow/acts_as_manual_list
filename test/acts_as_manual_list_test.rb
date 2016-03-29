require 'active_support'
require 'active_record'

require 'acts_as_manual_list'

require 'minitest/autorun'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveSupport::TestCase.test_order = :random

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :parents do |t|
    t.string :name
  end

  create_table :children do |t|
    t.integer :parent_id
    t.integer :position
    t.string :name
  end
  add_foreign_key :children, :parents, column: :parent_id
  add_index :children, [:parent_id, :position], unique: true
end

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
end

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true
end

class Parent < ApplicationModel
  has_many :children, inverse_of: :parent
end

class Child < ApplicationModel
  belongs_to :parent, inverse_of: :children
  acts_as_manual_list scope: :parent
end

class ActsAsManualList::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, ActsAsManualList
  end

  test "remove_many" do

  end

  test "list positioning updates" do
    # We use negative to designate new, and abs() to derive position
    list = [
      {:pos => 8}, # prepended, added at -1.0
      {:pos => 9}, # prepended, added at  0.0
      {:pos => 1, :in_list => true}, # stable, remains at   1.0
      {:pos => 10}, # insert, at           1.25
      {:pos => 10, :in_list => true}, # reordered to         1.50
      {:pos => 11, :in_list => true}, # reordered to         1.75
      {:pos => 2, :in_list => true}, # stable, remains at   2.0
      {:pos => 3, :in_list => true}, # stable, remains at   3.0
      {:pos => 4, :in_list => true}, # stable, remains at   4.0
      {:pos => 11}, # appended, added at   5.0
      {:pos => 12}, # appended, added at   6.0
    ]

    Child.interleaved_positions(
      list,
      in_list:  ->(x){ x[:in_list] },
      position: ->(x){ x[:pos].to_f }) { |x, y| x[:to] = y}

    assert_equal([
                   {:pos => 8, :to => -1.0},
                   {:pos => 9, :to => 0.0},
                   {:pos => 1},
                   {:pos => 10, :to => 1.25},
                   {:pos => 10, :to => 1.50},
                   {:pos => 11, :to => 1.75},
                   {:pos => 2},
                   {:pos => 3},
                   {:pos => 4},
                   {:pos => 11, :to => 5.0},
                   {:pos => 12, :to => 6.0},
                 ],
                 list.map{|x| x.delete(:in_list)})
  end
end

