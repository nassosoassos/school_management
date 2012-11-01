class CreateOldStudentSemesters < ActiveRecord::Migration
  def self.up
    create_table :old_student_semesters do |t|
      t.string :StudentSemesterId
      t.string :SemesterId
      t.string :StudentId
      t.float :Qualifications
      t.float :MeanAvgUniv
      t.float :UniversityUnits
      t.float :MeanAvgMil
      t.float :MilitaryUnits
      t.float :Seniority
      t.string :StudentSemLessonAssociateId
      t.string :LessonSemesterAssociateId
      t.float :GradeA
      t.float :GradeB
      t.float :GradeC

      t.timestamps
    end
  end

  def self.down
    drop_table :old_student_semesters
  end
end
