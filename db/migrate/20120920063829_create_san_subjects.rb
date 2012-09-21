class CreateSanSubjects < ActiveRecord::Migration
  def self.up
    create_table :san_subjects do |t|
      t.string :title
      t.string :kind

      t.timestamps
    end
  end

  def self.down
    drop_table :san_subjects
  end
end
