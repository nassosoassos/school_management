class AddMothersFirstNameAndOldIdToArchivedStudent < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :mothers_first_name, :string
    add_column :archived_students, :old_id, :string
  end

  def self.down
    remove_column :archived_students, :old_id
    remove_column :archived_students, :mothers_first_name
  end
end
