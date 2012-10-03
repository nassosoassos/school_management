class AddSemesterIdToStudentsSubject < ActiveRecord::Migration
  def self.up
    change_table :students_subjects do |t|
       t.references :san_semester
    end
  end

  def self.down
    remove_column :students_subjects, :semester_id
  end
end
