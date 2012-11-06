class OldStudentSemester < ActiveRecord::Base

  def self.synchronize
    old_student_semesters = OldStudentSemester.all

    old_student_semesters.each do |stu_sem|
      new_student = Student.find_by_old_id(stu_sem.StudentId)   
      new_semester = SanSemester.find_by_old_id(stu_sem.SemesterId)
      new_semester_subject = SemesterSubjects.find_by_old_id(stu_sem.LessonSemesterAssociateId)
      new_stu_sem_academic_year = new_semester.academic_year
      existing_stu_sem = StudentsSubject.find_all_by_student_id_and_academic_year_id_and_subject_id_and_semester_subjects_id(new_student.id, new_stu_sem_academic_year.id, new_semester_subject.subject_id, new_semester_subject.id)
      if existing_stu_sem.empty?
        new_stu_sem = StudentsSubject.new({:student_id=>new_student.id, :san_semester_id=>new_semester.id, :academic_year_id=>new_stu_sem_academic_year.id, :group_id=>new_student.group_id, :a_grade=>stu_sem.GradeA, :b_grade=>stu_sem.GradeB, :c_grade=>stu_sem.GradeC, :old_id=>stu_sem.id, :subject_id=>new_semester_subject.subject_id, :semester_subjects_id=>new_semester_subject.id })
        new_stu_sem.save
      else
        puts "%s %s %s %s %s %s" % [new_student.id, new_stu_sem_academic_year.name, new_semester_subject.san_subject.title, stu_sem.GradeA.to_s, stu_sem.GradeB.to_s, stu_sem.GradeC.to_s]
      end
      new_stu_mil_perf = StudentMilitaryPerformance.find_or_create_by_student_id_and_academic_year_id(new_student.id, new_semester.academic_year.id)
      grade = stu_sem.Qualifications
      unless grade.blank?
        new_stu_mil_perf.update_attributes({:grade=>grade})
      end
    end
    return StudentsSubject.all.length
  end
end
