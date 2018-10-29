# frozen_string_literal: true

require 'lazily'
require 'iknow_list_utils'

module ActsAsManualList
  using IknowListUtils

  POSITION_GETTER = ->(el)    { el.send(:position) }
  POSITION_SETTER = ->(el, v) { el.send(:position=, v) }

  # Takes an list of elements in a desired order. Elements have an inherent
  # float position, obtainable via `position_getter`, which may be nil if the
  # element previously was not a list member. For each element whose position
  # is not in order (i.e. between the positions of its neighbours), calls
  # `position_setter` to update the position to a new float value.
  # Returns the count of elements whose positions were changed.
  def self.update_positions(elements,
                            position_getter: POSITION_GETTER,
                            position_setter: POSITION_SETTER)

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
                                            [[nil, elements.size]])

    # For each possible range of indices that are not stable (i.e. for every
    # adjacent pair of stable indices), assign new positions distributed
    # between the stable positions.
    changed_positions = 0
    stable_position_indices.each_cons(2) do |(start_pos, start_index), (end_pos, end_index)|
      range = (start_index + 1)..(end_index - 1)
      next if range.size.zero?

      changed_positions += range.size
      new_positions = select_positions(start_pos, end_pos, range.size)

      new_positions.each.with_index(1) do |new_pos, offset|
        position_setter.(elements[start_index + offset], new_pos)
      end
    end

    changed_positions
  end

  # Select `count` positions in order between the provided `start_pos` and `end_pos`
  def self.select_positions(start_pos, end_pos, count)
    case
    when start_pos.nil? && end_pos.nil?
      # all elements are unpositioned, assign sequentially
      1.upto(count).map(&:to_f)
    when start_pos.nil?
      # before first fixed element
      count.downto(1).map { |i| end_pos - i }
    when end_pos.nil?
      # after last fixed element
      1.upto(count).map { |i| start_pos + i }
    else
      delta = (end_pos - start_pos) / (count + 1)
      1.upto(count).map { |i| start_pos + (delta * i) }
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
elsif defined?(ActiveRecord)
  ActiveRecord::Base.send(:include, ActsAsManualList::Base)
end
