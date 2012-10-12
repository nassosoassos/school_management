class ChangeDataTypeForStudentsSubjectGrades < ActiveRecord::Migration
  def self.up
    change_column :students_subjects, :a_grade, :float
    change_column :students_subjects, :b_grade, :float
    change_column :students_subjects, :c_grade, :float
  end

  def self.down
    change_column :students_subjects, :a_grade, :integer
    change_column :students_subjects, :b_grade, :integer
    change_column :students_subjects, :c_grade, :integer
  end
end
