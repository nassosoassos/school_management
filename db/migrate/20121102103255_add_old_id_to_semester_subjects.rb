class AddOldIdToSemesterSubjects < ActiveRecord::Migration
  def self.up
    add_column :semester_subjects, :old_id, :string
  end

  def self.down
    remove_column :semester_subjects, :old_id
  end
end
