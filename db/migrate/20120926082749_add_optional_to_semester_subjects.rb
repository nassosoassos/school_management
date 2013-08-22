class AddOptionalToSemesterSubjects < ActiveRecord::Migration
  def self.up
    add_column :semester_subjects, :optional, :boolean
  end

  def self.down
    remove_column :semester_subjects, :optional
  end
end
