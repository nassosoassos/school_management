class CreateStudentMilitaryPerformances < ActiveRecord::Migration
  def self.up
    create_table :student_military_performances do |t|
      t.integer :grade
      t.references :student
      t.references :san_semester

      t.timestamps
    end
  end

  def self.down
    drop_table :student_military_performances
  end
end
