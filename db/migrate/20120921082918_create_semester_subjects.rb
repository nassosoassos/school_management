class CreateSemesterSubjects < ActiveRecord::Migration
  def self.up
    create_table :semester_subjects do |t|
      t.integer :semester_id
      t.integer :subject_id

      t.timestamps
    end
    add_index :semester_subjects, :semester_id
    add_index :semester_subjects, :subject_id
    add_index :semester_subjects, [:semester_id, :subject_id], :unique => true
  end

  def self.down
    drop_table :semester_subjects
  end
end
