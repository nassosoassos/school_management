class RemoveIndexStudentsSubjects < ActiveRecord::Migration
  def self.up
      #remove_index :students_subjects, :name=>"student_subject_year_index"
  end

  def self.down
      add_index :students_subjects, [:student_id,:subject_id,:academic_year_id]
  end
end
