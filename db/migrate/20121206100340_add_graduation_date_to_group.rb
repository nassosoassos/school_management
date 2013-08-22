class AddGraduationDateToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :graduation_date, :date
  end

  def self.down
    remove_column :groups, :graduation_date
  end
end
