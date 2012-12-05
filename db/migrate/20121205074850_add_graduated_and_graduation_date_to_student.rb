class AddGraduatedAndGraduationDateToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :graduated, :boolean, :default=>false
    add_column :students, :graduation_leave_date, :date
  end

  def self.down
    remove_column :students, :graduated
    remove_column :students, :graduation_leave_date
  end
end
