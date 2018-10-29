# frozen_string_literal: true

require 'active_support/concern'
require 'active_record'

module ActsAsManualList::Base
  extend ActiveSupport::Concern

  module ClassMethods
    def acts_as_manual_list(scope:, attribute: :position)
      include ActsAsManualList::ListMember
      self.acts_as_list_scope = scope
      self.acts_as_list_attribute = attribute
    end
  end
end
