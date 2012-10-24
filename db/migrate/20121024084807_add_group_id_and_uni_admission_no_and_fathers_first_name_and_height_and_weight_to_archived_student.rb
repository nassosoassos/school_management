class AddGroupIdAndUniAdmissionNoAndFathersFirstNameAndHeightAndWeightToArchivedStudent < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :group_id, :integer
    add_column :archived_students, :uni_admission_no, :string
    add_column :archived_students, :fathers_first_name, :string
    add_column :archived_students, :height, :integer
    add_column :archived_students, :weight, :integer
  end

  def self.down
    remove_column :archived_students, :weight
    remove_column :archived_students, :height
    remove_column :archived_students, :fathers_first_name
    remove_column :archived_students, :uni_admission_no
    remove_column :archived_students, :group_id
  end
end
