class AddGradesToStudentsSubject < ActiveRecord::Migration
  def self.up
    add_column :students_subjects, :a_grade, :integer
    add_column :students_subjects, :b_grade, :integer
    add_column :students_subjects, :c_grade, :integer
  end

  def self.down
    remove_column :students_subjects, :c_grade
    remove_column :students_subjects, :b_grade
    remove_column :students_subjects, :a_grade
  end
end
