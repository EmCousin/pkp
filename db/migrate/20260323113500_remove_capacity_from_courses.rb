# frozen_string_literal: true

# NOTE: This migration is intentionally commented out.
# The capacity column is kept on the courses table for backward compatibility
# during the transition period. It can be removed in a future migration once
# all code has been updated to use capacities_courses exclusively.
#
# See PR #610 for more details.

class RemoveCapacityFromCourses < ActiveRecord::Migration[8.0]
  def change
    # Keeping capacity column for backward compatibility
    # Migration preserved for historical context
  end
end
