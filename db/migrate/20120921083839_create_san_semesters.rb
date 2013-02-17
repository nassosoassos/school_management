class CreateSanSemesters < ActiveRecord::Migration
  def self.up
    create_table :san_semesters do |t|
      t.integer :number
      t.integer :group_id
      t.integer :uni_weight
      t.integer :mil_weight

      t.timestamps
    end
  end

  def self.down
    drop_table :san_semesters
  end
end
