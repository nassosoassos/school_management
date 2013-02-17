class ChangeYearsToDateGroups < ActiveRecord::Migration
  def self.up
    change_column :groups, :first_year, :date
    change_column :groups, :graduation_year, :date
  end

  def self.down
    change_column :groups, :first_year, :datetime
    change_column :groups, :graduation_year, :datetime
  end
end
