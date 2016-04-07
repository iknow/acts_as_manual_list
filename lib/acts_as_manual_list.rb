require 'lazily'
require 'iknow_list_utils'

module ActsAsManualList
  using IknowListUtils

  # Takes an list of elements in a desired order. Elements have an inherent
  # float position, obtainable via `position_getter`, which may be nil if the
  # element previously was not a list member. For each element whose position
  # is not in order (i.e. between the positions of its neighbours), calls
  # `position_setter` to update the position to a new float value.
  def self.update_positions(elements,
                            position_getter: ->(el   ){ el.send(:position) },
                            position_setter: ->(el, v){ el.send(:position=, v) })

    # calculate index for each previously existing position
    position_indices = elements
                       .lazy
                       .with_index
                       .map    { |el, i| [position_getter.(el), i] }
                       .reject { |p, i| p.nil? }
                       .to_a

    # TODO we haven't dealt with collisions

    # Calculate stable points in the element array which don't need to have
    # positions updated:
    # * before the beginning of the ordered subsequence
    # * a subsequence of elements which are already in order
    # * after the end of the ordered subsequence.
    stable_position_indices = Lazily.concat([[nil, -1]],
                                            position_indices.longest_rising_sequence_by(&:first),
                                            [[nil, elements.length]])

    # For each possible range of indices that are not stable (i.e. for every
    # adjacent pair of stable indices), assign new positions distributed
    # between the stable positions.
    stable_position_indices.each_cons(2) do |(start_pos, start_index), (end_pos, end_index)|
      range = (start_index + 1)..(end_index - 1)
      next unless range.size > 0

      new_positions =
        case
        when start_pos.nil? && end_pos.nil?
          # all elements are unpositioned, assign sequentially
          range
        when start_pos.nil?
          # before first fixed element
          range.size.downto(1).map { |i| end_pos - i }
        when end_pos.nil?
          # after last fixed element
          1.upto(range.size).map { |i| start_pos + i }
        else
          delta = (end_pos - start_pos) / (range.size + 1)
          1.upto(range.size).map { |i| start_pos + delta * i }
        end

      new_positions.each.with_index(1) do |new_pos, offset|
        position_setter.(elements[start_index + offset], new_pos)
      end
    end
  end
end

# Install into ActiveRecord
require 'acts_as_manual_list/base'
require 'acts_as_manual_list/list_member'

if defined?(Rails::Railtie)
  class Railtie < Rails::Railtie
    initializer 'acts_as_manual_list.insert_into_active_record' do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.send(:include, ActsAsManualList::Base)
      end
    end
  end
else
  ActiveRecord::Base.send(:include, ActsAsManualList::Base) if defined?(ActiveRecord)
end
