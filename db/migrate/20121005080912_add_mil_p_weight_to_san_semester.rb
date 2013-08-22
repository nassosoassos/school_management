class AddMilPWeightToSanSemester < ActiveRecord::Migration
  def self.up
    add_column :san_semesters, :mil_p_weight, :integer
  end

  def self.down
    remove_column :san_semesters, :mil_p_weight
  end
end
