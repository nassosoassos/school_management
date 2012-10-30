class ChangeYearToReferenceAcademicYearSanSemester < ActiveRecord::Migration
  def self.up
    remove_column :san_semesters, :year
    change_table :san_semesters do |t|
      t.references :academic_year
    end
  end

  def self.down
    add_column :san_semesters, :year
    remove_column :san_semesters, :academic_year_id
  end
end
