class CreateAcademicYears < ActiveRecord::Migration
  def self.up
    create_table :academic_years do |t|
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
    add_index :academic_years, :start_date, {:name=>"start_date_index", :unique=>"true"}
  end

  def self.down
    drop_table :academic_years
  end
end
