class AddUniqueIndexToSanSemesters < ActiveRecord::Migration
  def self.up
    add_index :san_semesters, [:number, :academic_year_id], {:name=>"number_academic_year", :unique=>true}
  end

  def self.down
    remove_index :san_semesters, "number_academic_year"
  end
end
