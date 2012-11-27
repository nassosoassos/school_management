class AddColumnsToStudentMilitaryPerformance < ActiveRecord::Migration
  def self.up
    add_column :student_military_performances, :seniority, :integer
    add_column :student_military_performances, :gpa, :float
    add_column :student_military_performances, :univ_gpa, :float
    add_column :student_military_performances, :mil_gpa, :float
    add_column :student_military_performances, :points, :float
    add_column :student_military_performances, :univ_points, :float
    add_column :student_military_performances, :mil_points, :float
    add_column :student_military_performances, :n_unfinished_subjects, :integer
    add_column :student_military_performances,
  end

  def self.down
  end
end
