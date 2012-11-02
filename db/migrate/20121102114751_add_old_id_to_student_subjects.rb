class AddOldIdToStudentSubjects < ActiveRecord::Migration
  def self.up
    add_column :students_subjects, :old_id, :string
  end

  def self.down
    remove_column :students_subjects, :old_id
  end
end
