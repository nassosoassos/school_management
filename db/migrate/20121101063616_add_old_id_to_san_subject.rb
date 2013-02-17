class AddOldIdToSanSubject < ActiveRecord::Migration
  def self.up
    add_column :san_subjects, :old_id, :string
  end

  def self.down
    remove_column :san_subjects, :old_id
  end
end
