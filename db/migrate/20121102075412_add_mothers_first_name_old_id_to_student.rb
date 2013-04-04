class AddMothersFirstNameOldIdToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :mothers_first_name, :string
    add_column :students, :old_id, :string
  end

  def self.down
    remove_column :students, :mothers_first_name
    remove_column :students, :old_id
  end
end
