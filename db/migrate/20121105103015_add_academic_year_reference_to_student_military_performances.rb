class AddAcademicYearReferenceToStudentMilitaryPerformances < ActiveRecord::Migration
  def self.up
    change_table :student_military_performances do |t|
      t.references :academic_year
    end
    remove_column :student_military_performances, :san_semester_id
  end

  def self.down
    change_table :student_military_performances do |t|
      t.references :san_semester
    end
    remove_column :academic_year_id
  end
end
