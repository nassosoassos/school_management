class AddUniqueIndexToStudentsSubjects < ActiveRecord::Migration
  def self.up
    change_table :students_subjects do |t|
      t.references :semester_subjects
    end
    add_index :students_subjects, [:student_id, :semester_subjects_id, :san_semester_id], {:name=>"student_subject_semester", :unique=>true}
  end

  def self.down
    remove_column :semester_subjects_id
    remove_index :students_subjects, "student_subject_semester"
  end
end
