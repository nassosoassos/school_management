class AddColumnsToStudentMilitaryPerformance < ActiveRecord::Migration
  def self.up
    change_table :student_military_performances do |t|
      t.references :group
    end
    add_column :student_military_performances, :is_active, :boolean, :default=>true
    add_column :student_military_performances, :seniority, :integer
    add_column :student_military_performances, :gpa, :float
    add_column :student_military_performances, :univ_gpa, :float
    add_column :student_military_performances, :mil_gpa, :float
    add_column :student_military_performances, :points, :float
    add_column :student_military_performances, :univ_points, :float
    add_column :student_military_performances, :mil_points, :float
    add_column :student_military_performances, :mil_p_points, :float
    add_column :student_military_performances, :n_unfinished_subjects, :integer
    add_column :student_military_performances, :success_type, :integer
    add_column :student_military_performances, :cum_gpa, :float
    add_column :student_military_performances, :cum_points, :float
    add_column :student_military_performances, :cum_univ_gpa, :float
    add_column :student_military_performances, :cum_mil_gpa, :float
    add_column :student_military_performances, :cum_mil_p_gpa, :float
    add_column :student_military_performances, :cum_n_unfinished_subjects, :integer
    add_column :student_military_performances, :cum_seniority, :integer
  end

  def self.down
    remove_column :student_military_performances, :seniority
    remove_column :student_military_performances, :gpa
    remove_column :student_military_performances, :univ_gpa
    remove_column :student_military_performances, :mil_gpa
    remove_column :student_military_performances, :points
    remove_column :student_military_performances, :univ_points
    remove_column :student_military_performances, :mil_points
    remove_column :student_military_performances, :mil_p_points
    remove_column :student_military_performances, :n_unfinished_subjects
    remove_column :student_military_performances, :cum_gpa
    remove_column :student_military_performances, :cum_points
    remove_column :student_military_performances, :cum_univ_gpa
    remove_column :student_military_performances, :cum_mil_gpa
    remove_column :student_military_performances, :cum_mil_p_gpa
    remove_column :student_military_performances, :cum_n_unfinished_subjects
    remove_column :student_military_performances, :cum_seniority
    remove_column :student_military_performances, :group_id
    remove_column :student_military_performances, :is_active
    remove_column :student_military_performances, :success_type
  end
end
