require 'active_support/all'
require 'active_record'

require 'lazily'
require 'iknow_list_utils'

module ActsAsManualList
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :acts_as_list_scope, :acts_as_list_attribute
    end
  end

  module ClassMethods
    using IknowListUtils

    def interleaved_positions(elements, in_list: nil, position: nil)
      in_list  ||= ->(_) { false }
      position ||= ->(x) { x.send(:position) }

      position_indices = elements
                           .lazy
                           .with_index
                           .select { |c, _| in_list.(c)           }
                           .map    { |c, i| [position.(c), i] }
                           .to_a

      # TODO we haven't dealt with collisions

      stable_positions = Lazily.concat([[nil, -1]],
                                       position_indices.longest_rising_sequence_by(&:first),
                                       [[nil, elements.length]])

      stable_positions.each_cons(2) do |(start_pos, start_index), (end_pos, end_index)|
        range = (start_index + 1)..(end_index - 1)
        next unless range.size > 0

        positions =
          case
          when start_pos.nil? && end_pos.nil?
            range
          when start_pos.nil? # before first fixed element
            range.size.downto(1).map { |i| end_pos - i }
          when end_pos.nil? # after
            1.upto(range.size).map { |i| start_pos + i }
          else
            delta = (end_pos - start_pos) / (range.size + 1)
            1.upto(range.size).map { |i| start_pos + delta * i }
          end

        positions.each.with_index(1) do |pos, i|
          yield elements[i + start_index], pos
        end
      end
    end

    def set_positions(parent, children, in_list:)
      get_pos = :"#{acts_as_list_attribute}"
      set_pos = :"#{acts_as_list_attribute}="

      # By considering stable positions only from existing children we favor them as stable positions. Other children
      # will have their parent pointer changed, so they're being modified anyway.

      interleaved_positions(children,
                            in_list: in_list,
                            position: ->(x) { x.public_send(get_pos) }) do |c, pos|
        c.public_send(set_pos, pos)
      end
    end

  end

  # TODO... list motion, append/prepend/etc
  # append from list
  # insert at position
  # remove from list # will need to move from list to list

end

module ActsAsListBase
  extend ActiveSupport::Concern

  module ClassMethods
    def acts_as_manual_list(scope:, attribute: nil)
      @acts_as_list_scope = scope
      @acts_as_list_attribute = attribute || :position
      include ActsAsManualList
    end
  end
end


ActiveRecord::Base.send(:include, ActsAsListBase)

# Child.remove_many(parent_instance, indexes..)
