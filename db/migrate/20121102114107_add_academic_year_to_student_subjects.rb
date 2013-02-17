class AddAcademicYearToStudentSubjects < ActiveRecord::Migration
  def self.up
    change_table :students_subjects do |t|
      t.references :academic_year
    end

  end

  def self.down
    remove_column :students_subjects, :academic_year
  end
end
