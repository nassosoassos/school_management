class ChangeGraduatedDefaultValueGroups < ActiveRecord::Migration
  def self.up
    change_column :groups, :graduated, :boolean, :default=>false
  end

  def self.down
    change_column :groups, :graduated, :boolean, :default=>true
  end
end
