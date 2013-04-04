class AddGroupIdToStudent < ActiveRecord::Migration
  def self.up
    change_table :students do |t|
	t.references :group
    end
  end

  def self.down
    remove_column :students, :group_id
  end
end
