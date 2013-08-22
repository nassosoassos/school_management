class AddUniAdmissionNoAndFathersFirstNameAndHeightAndWeightToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :uni_admission_no, :string
    add_column :students, :fathers_first_name, :string
    add_column :students, :height, :integer
    add_column :students, :weight, :integer
  end

  def self.down
    remove_column :students, :weight
    remove_column :students, :height
    remove_column :students, :fathers_first_name
    remove_column :students, :uni_admission_no
  end
end
