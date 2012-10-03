class AddGroupIdToStudentsSubject < ActiveRecord::Migration
  def self.up
    change_table :students_subjects do |t|
       t.references :group
    end
  end

  def self.down
    remove_column :students_subjects, :group_id
  end
end
