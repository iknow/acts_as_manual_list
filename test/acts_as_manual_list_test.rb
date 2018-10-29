# frozen_string_literal: true

require 'active_support'
require 'active_record'

require 'acts_as_manual_list'

require 'minitest/autorun'

# ActiveRecord::Base.logger = Logger.new(STDOUT)
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
  Element = Struct.new(:id, :position)

  test 'truth' do
    assert_kind_of Module, ActsAsManualList
  end

  test 'remove_many' do
  end

  test 'list initialization' do
    list = 1.upto(3).map { |i| Element.new(i) }

    ActsAsManualList.update_positions(list)

    expected = [
      Element.new(1, 1.0),
      Element.new(2, 2.0),
      Element.new(3, 3.0),
    ]

    assert_equal(expected, list)
  end

  test 'list positioning updates' do
    # We use negative to designate new, and abs() to derive position
    list = [
      Element.new(1),       # prepended, added at -1.0
      Element.new(2),       # prepended, added at  0.0
      Element.new(3, 1.0),  # stable, remains at   1.0
      Element.new(4),       # insert, at           1.25
      Element.new(5, 10.0), # reordered to         1.50
      Element.new(6, 11.0), # reordered to         1.75
      Element.new(7, 2.0),  # stable, remains at   2.0
      Element.new(8, 3.0),  # stable, remains at   3.0
      Element.new(9, 4.0),  # stable, remains at   4.0
      Element.new(10),      # appended, added at   5.0
      Element.new(11),      # appended, added at   6.0
    ]

    ActsAsManualList.update_positions(list)

    expected = [
      Element.new(1, -1.0),
      Element.new(2,  0.0),
      Element.new(3,  1.0),
      Element.new(4,  1.25),
      Element.new(5,  1.50),
      Element.new(6,  1.75),
      Element.new(7,  2.0),
      Element.new(8,  3.0),
      Element.new(9,  4.0),
      Element.new(10, 5.0),
      Element.new(11, 6.0),
    ]

    assert_equal(expected, list)
  end

  test 'setters and getters' do
    list = [
      { id: 1 },            # prepended, added at -1.0
      { id: 2 },            # prepended, added at  0.0
      { id: 3, pos: 1.0 },  # stable, remains at   1.0
    ]

    ActsAsManualList.update_positions(
      list,
      position_getter: ->(x) { x[:pos] },
      position_setter: ->(x, y) { x[:pos] = y })

    expected = [
      { id: 1, pos: -1.0 },
      { id: 2, pos: 0.0 },
      { id: 3, pos: 1 },
    ]
    assert_equal(expected, list)
  end
end
