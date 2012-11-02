class OldStudentSemester < ActiveRecord::Base

  def self.synchronize
    old_student_semesters = OldStudentSemester.all

    old_student_semesters.each do |stu_sem|
      new_student = Student.find_by_old_id(stu_sem.StudentId)   
      new_semester = SanSemester.find_by_old_id(stu_sem.SemesterId)
      new_semester_subject = SemesterSubjects.find_by_old_id(stu_sem.LessonSemesterAssociateId)
      new_stu_sem = StudentsSubject.new({:student_id=>new_student.id, :san_semester_id=>new_semester.id, :academic_year_id=>new_semester.academic_year.id, :group_id=>new_student.group_id, :a_grade=>stu_sem.GradeA, :b_grade=>stu_sem.GradeB, :c_grade=>stu_sem.GradeC, :old_id=>stu_sem.id, :subject_id=>new_semester_subject.subject_id })
      new_stu_sem.save

      new_stu_mil_perf = StudentMilitaryPerformance.find_or_create_by_student_id_and_san_semester_id_and_grade(new_student.id, new_semester.id, stu_sem.Qualifications)
    end
  end
end
