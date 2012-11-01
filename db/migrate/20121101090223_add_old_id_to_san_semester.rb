class AddOldIdToSanSemester < ActiveRecord::Migration
  def self.up
    add_column :san_semesters, :old_id, :string
  end

  def self.down
    remove_column :san_semesters, :old_id
  end
end
