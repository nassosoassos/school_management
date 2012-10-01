class AddYearToSanSemester < ActiveRecord::Migration
  def self.up
    add_column :san_semesters, :year, :string
  end

  def self.down
    remove_column :san_semesters, :year
  end
end
