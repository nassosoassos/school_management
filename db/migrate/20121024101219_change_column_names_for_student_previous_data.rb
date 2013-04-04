class ChangeColumnNamesForStudentPreviousData < ActiveRecord::Migration
  def self.up
    rename_column :student_previous_datas, :year, :admission_points 
    rename_column :student_previous_datas, :course, :admission_rank 

    change_column :student_previous_datas, :admission_points, :integer
    change_column :student_previous_datas, :admission_rank, :integer
    change_column :student_previous_datas, :total_mark, :integer
  end

  def self.down
    change_column :student_previous_datas, :admission_points, :string
    change_column :student_previous_datas, :admission_rank, :string
    change_column :student_previous_datas, :total_mark, :string


    rename_column :student_previous_datas, :admission_points, :year
    rename_column :student_previous_datas, :admission_rank, :course 
  end
end
