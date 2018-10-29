# frozen_string_literal: true

require 'active_support/concern'
require 'active_record'

module ActsAsManualList::ListMember
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :acts_as_list_scope, :acts_as_list_attribute
    end
  end

  module ClassMethods
    # TODO: inject something like this into the scope class
    # def reorder_#{association}(children)
    #   ChildType.set_positions(self, children)
    # end

    def set_positions(_parent, children)
      # TODO: validate that the children are all children of the parent.

      # Optimization: if a child record is already `changed?`, then it's going
      # to be written no matter what. If we don't consider changed records for
      # selecting stable positions (i.e. ignore their previous `position` field)
      # we can maximize the chance of avoiding updates to otherwise untouched
      # rows.
      get_pos = ->(el) do
        if el.changed?
          nil
        else
          el.public_send(acts_as_list_attribute)
        end
      end

      set_pos = ->(el, p) { el.public_send(:"#{acts_as_list_attribute}=", p) }

      ActsAsManualList.update_positions(children, position_getter: get_pos, position_setter: set_pos)
    end
  end

  # TODO... list motion, append/prepend/etc
  # append from list
  # insert at position
  # remove from list # will need to move from list to list
end
