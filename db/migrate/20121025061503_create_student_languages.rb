class CreateStudentLanguages < ActiveRecord::Migration
  def self.up
    create_table :student_languages do |t|
      t.references :foreign_language
      t.references :student
      t.string :knowledge

      t.timestamps
    end
  end

  def self.down
    drop_table :student_languages
  end
end
