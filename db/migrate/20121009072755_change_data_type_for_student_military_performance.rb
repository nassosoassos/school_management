class ChangeDataTypeForStudentMilitaryPerformance < ActiveRecord::Migration
  def self.up
    change_column :student_military_performances, :grade, :float
  end

  def self.down
    change_column :student_military_performances, :grade, :integer
  end
end
