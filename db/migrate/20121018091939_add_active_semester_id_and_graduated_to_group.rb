class AddActiveSemesterIdAndGraduatedToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :graduated, :boolean, :default=>false
    add_column :groups, :active_semester_id, :integer
    change_table :groups do |t|
      t.references :san_semester
    end

  end

  def self.down
    remove_column :groups, :graduated
    remove_column :groups, :active_semester_id
  end
end
