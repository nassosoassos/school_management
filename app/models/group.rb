class Group < ActiveRecord::Base
  has_many :san_semesters
  has_many :students
  has_many :students_subjects

  validates_presence_of :name, :first_year, :graduation_year

  def next
    # Sort groups by graduation year
    groups = Groups.find(:all, :order=>"graduation_year")
    self_ind = groups.index {|a| a.id==self.id}
    next_ind = self_ind + 1
    if next_ind==groups.length
      next_ind = self_ind
    end
    return groups[next_ind]
  end

  def previous
    # Sort groups by graduation year
    groups = Groups.find(:all, :order=>"graduation_year")
    self_ind = groups.index {|a| a.id==self.id}
    previous_ind = self_ind - 1
    if self_ind==0
      previous_ind = self_ind
    end
    return groups[previous_ind]
  end

  def get_not_graduated_students
    return Student.find_all_by_group_id_and_graduated(self.id, false)
  end

  def n_students(year=nil)
    if year.nil?
      g_students = Student.find_all_by_group_id_and_is_active(self.id, true)
      if g_students.empty?
        return 0
      else
        return g_students.length
      end
    else
      g_students = Student.find_all_by_group_id(self.id)
      num = 0
      g_students.each do |s|
        if StudentMilitaryPerformance.find_by_student_id_and_academic_year_id_and_is_active(s.id, year.id, true)
          num += 1
        end
      end
      return num
    end
  end

  #def estimate_seniority_batch(year)
  #  all_students = Student.find_all_by_group_id(self.id, true)
  #  all_students.each do |stu|
  #    if stu.is_active_for_year(year)
  #      stu.estimate_performance_scores(year)
  #    end
  #  end
  #  return all_students.length
  #end

  def graduate(graduation_date)
    students = Student.find_all_by_group_id_and_is_active(self.id, true)
    graduation_year = self.last_year
    students.each do |stu|
      if stu.get_to_be_transferred_subjects_for_year(self.last_year).length==0
        stu.graduate(graduation_date, nil)
      else
        graduation_year.create_next_year
        stu.validate_subject_grades(graduation_year)
      end
    end
    self.update_attributes({:graduated=>true, :graduation_date=>graduation_date})
  end

  def revert_graduation
    students = Student.find_all_by_group_id_and_is_active(self.id, true)
    students.each do |stu|
      if stu.get_to_be_transferred_subjects_for_year(self.last_year).length==0
        stu.revert_graduation
      end
    end
    self.update_attributes({:graduated=>false, :graduation_date=>nil})
  end

  def reset_cum_seniority
    all_students = Student.find_all_by_group_id(self.id)
    all_students.each do |stu|
      smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(stu.id, self.last_year.id)
      smp.update_attributes({:cum_seniority=>nil})
    end
    return all_students.length
  end

  def reset_seniority(year)
    all_students = Student.find_all_by_group_id(self.id)
    all_students.each do |stu|
      smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(stu.id, year.id)
      smp.update_attributes({:seniority=>nil})
    end
    return all_students.length
  end

  def get_seniority(year)
    smps = StudentMilitaryPerformance.find(:all, :conditions=>{:group_id=>self.id, :academic_year_id=>year.id, :seniority=>1..200})
    sorted_smps = smps.sort {|a,b| a.seniority<=>b.seniority}
    return sorted_smps.map(&:student).map(&:last_name), sorted_smps.map(&:seniority), sorted_smps.map(&:points)
  end

  def estimate_cum_seniority(student_id)
    # In case we know that a specific student has been updated
    # we can save the full sorting
    group_last_year = self.last_year
    stu_smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(student_id, group_last_year.id)
    if stu_smp.cum_seniority.nil?
      smps = StudentMilitaryPerformance.find(:all, :conditions=>{:academic_year_id=>group_last_year.id, :group_id=>self.id, :cum_seniority=>1..200})
      stu_smp.update_attributes({:cum_seniority=>smps.length+1})
    end
    stu_smp_higher = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_cum_seniority(group_last_year.id, self.id, stu_smp.cum_seniority-1)
    pos = 0
    unless stu_smp_higher.nil?
      while stu_smp_higher and stu_smp.cum_points and
          (stu_smp_higher.cum_points.nil? or stu_smp_higher.n_unfinished_subjects>stu_smp.n_unfinished_subjects or
              (stu_smp_higher.n_unfinished_subjects==stu_smp.n_unfinished_subjects and (stu_smp_higher.cum_n_unfinished_subjects>stu_smp.cum_n_unfinished_subjects or
                  (stu_smp_higher.cum_n_unfinished_subjects==stu_smp.cum_n_unfinished_subjects and
                      ((stu_smp.cum_points-stu_smp_higher.cum_points > 0.001) or
                          ((stu_smp.cum_points-stu_smp_higher.cum_points).abs<0.001 and (stu_smp.cum_univ_gpa-stu_smp_higher.cum_univ_gpa>0.001 or
                              ((stu_smp.cum_univ_gpa-stu_smp_higher.cum_univ_gpa).abs<0.001 and stu_smp_higher.cum_mil_gpa<stu_smp.cum_mil_gpa))))))))
        stu_smp.update_attributes({:cum_seniority=>stu_smp_higher.cum_seniority})
        stu_smp_higher.update_attributes({:cum_seniority=>stu_smp.cum_seniority+1})
        stu_smp_higher = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_cum_seniority(
            group_last_year.id, self.id, stu_smp.cum_seniority-1)
        pos += 1
      end
    end

    if pos==0
      stu_smp_lower = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_cum_seniority(
          group_last_year.id, self.id, stu_smp.cum_seniority+1)
      pos = 0
      unless stu_smp_lower.nil?
        while stu_smp_lower and stu_smp_lower.cum_points and
            (stu_smp.cum_points.nil? or stu_smp_lower.n_unfinished_subjects<stu_smp.n_unfinished_subjects or
                (stu_smp_lower.n_unfinished_subjects==stu_smp.n_unfinished_subjects and (stu_smp_lower.cum_n_unfinished_subjects<stu_smp.cum_n_unfinished_subjects or
                    (stu_smp_lower.cum_n_unfinished_subjects==stu_smp.cum_n_unfinished_subjects and
                        ((stu_smp_lower.cum_points-stu_smp.cum_points > 0.001) or
                            ((stu_smp.cum_points-stu_smp_lower.cum_points).abs<0.001 and (stu_smp_lower.cum_univ_gpa-stu_smp_lower.cum_univ_gpa>0.001 or
                                ((stu_smp.cum_univ_gpa-stu_smp_lower.cum_univ_gpa).abs<0.001 and stu_smp_lower.cum_mil_gpa>stu_smp.cum_mil_gpa))))))))
          stu_smp.update_attributes({:cum_seniority=>stu_smp_lower.cum_seniority})
          stu_smp_lower.update_attributes({:cum_seniority=>stu_smp.cum_seniority-1})
          stu_smp_lower = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_cum_seniority(
              group_last_year.id, self.id, stu_smp.cum_seniority+1)
          pos += 1
        end
      end
    end
    return stu_smp.cum_seniority

  end

  def estimate_seniority(year, student_id)
    # In case we know that a specific student has been updated
    # we can save the full sorting
    stu_smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(student_id, year.id)
    if stu_smp.seniority.nil?
      smps = StudentMilitaryPerformance.find(:all, :conditions=>{:academic_year_id=>year.id, :group_id=>self.id, :seniority=>1..200})
      stu_smp.update_attributes({:seniority=>smps.length+1})
    end
    stu_smp_higher = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_seniority(year.id, self.id, stu_smp.seniority-1)
    pos = 0
    unless stu_smp_higher.nil?
      while stu_smp_higher and stu_smp.points and
          (stu_smp_higher.points.nil? or stu_smp_higher.success_type < stu_smp.success_type or
              (stu_smp_higher.success_type==stu_smp.success_type and (stu_smp_higher.n_unfinished_subjects>stu_smp.n_unfinished_subjects or
                  (stu_smp_higher.n_unfinished_subjects==stu_smp.n_unfinished_subjects and ((stu_smp.points-stu_smp_higher.points > 0.001) or
                      ((stu_smp.points-stu_smp_higher.points).abs<0.001 and (stu_smp.univ_gpa-stu_smp_higher.univ_gpa>0.001 or
                          ((stu_smp.univ_gpa-stu_smp_higher.univ_gpa).abs<0.001 and stu_smp_higher.mil_gpa<stu_smp.mil_gpa))))))))
        stu_smp.update_attributes({:seniority=>stu_smp_higher.seniority})
        stu_smp_higher.update_attributes({:seniority=>stu_smp.seniority+1})
        stu_smp_higher = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_seniority(
            year.id, self.id, stu_smp.seniority-1)
        pos += 1
      end
    end

    if pos==0
      stu_smp_lower = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_seniority(
          year.id, self.id, stu_smp.seniority+1)
      pos = 0
      unless stu_smp_lower.nil?
        while stu_smp_lower and stu_smp_lower.points and
            (stu_smp.points.nil? or stu_smp_lower.success_type > stu_smp.success_type or
                (stu_smp_lower.success_type==stu_smp.success_type and (stu_smp_lower.n_unfinished_subjects<stu_smp.n_unfinished_subjects or
                    (stu_smp_lower.n_unfinished_subjects==stu_smp.n_unfinished_subjects and ((stu_smp_lower.points-stu_smp.points > 0.001) or
                        ((stu_smp.points-stu_smp_lower.points).abs<0.001 and (stu_smp_lower.univ_gpa-stu_smp_lower.univ_gpa>0.001 or
                            ((stu_smp.univ_gpa-stu_smp_lower.univ_gpa).abs<0.001 and stu_smp_lower.mil_gpa>stu_smp.mil_gpa))))))))
          stu_smp.update_attributes({:seniority=>stu_smp_lower.seniority})
          stu_smp_lower.update_attributes({:seniority=>stu_smp.seniority-1})
          stu_smp_lower = StudentMilitaryPerformance.find_by_academic_year_id_and_group_id_and_seniority(
              year.id, self.id, stu_smp.seniority+1)
          pos += 1
        end
      end
    end
    return stu_smp.seniority
  end

  def unsubscribe_from_semester(semester)
    semester.update_attributes({:group_id=>nil})
    if self.active_semester_id == semester.id
      self.update_attributes({:active_semester_id=>nil})
    end

    # Unsubscribe all group students from the semester subjects
    group_students = Student.find_all_by_group_id(self.id)

    # Find if this is the only semester the group has subscribed to for the particular academic year
    semesters = SanSemester.find_all_by_group_id(self.id)
    delete_mil_performance = false
    if semesters.nil? or semesters.select{|a| a.academic_year_id == semester.academic_year_id}.empty?
      delete_mil_performance = true
    end

    if SanSemester.find_by_academic_year_id_and_group_id(semester.academic_year.id, self.id).nil?
      current_academic_year = self.last_year
    end

    group_students.each do |student|
      if delete_mil_performance
        student_performance = StudentMilitaryPerformance.delete(:student_id=>student.id, :academic_year_id=>semester.academic_year.id)
      end
      StudentsSubject.delete_all(:student_id=>student.id, :san_semester_id=>semester.id)

      if current_academic_year
        student.estimate_performance_scores(current_academic_year)
      end
    end
  end

  def find_year_number(year)
    academic_years = SanSemester.find_all_by_group_id(self.id).map(&:academic_year).uniq
    academic_years.sort!{|a, b| a.start_date<=>b.start_date}
    return academic_years.index{|a| a.id==year.id} + 1
  end

  def subscribe_to_semester_subjects(sem_subs)
    group_students = Student.find_all_by_group_id_and_is_active(self.id, true)
    group_students.each do |student|
      sem_subs.each do |sem_sub|
        stu_sub = StudentsSubject.find_or_create_by_student_id_and_san_semester_id_and_semester_subjects_id(student.id, sem_sub.san_semester.id, sem_sub.id)
        stu_sub.update_attributes({:group_id=>self.id, :academic_year_id=>sem_sub.san_semester.ac_year.id, :subject_id=>sem_sub.san_subject.id})
      end
    end
  end

  def subscribe_to_semester(semester)
    semester.update_attributes({:group_id=>self.id})
    self.update_attributes({:active_semester_id=>semester.id})

    # Subscribe all group students to the semester subjects
    group_students = Student.find_all_by_group_id_and_is_active(self.id, true)
    semester_subjects = SemesterSubjects.find_all_by_semester_id_and_optional(semester.id, false)
    ac_year = semester.academic_year
    previous_year = ac_year.previous

    group_students.each do |student|
      # Subscribe to the new classes
      semester_subjects.each do |sem_sub|
        stu_sub = StudentsSubject.find_or_create_by_student_id_and_san_semester_id_and_semester_subjects_id(student.id, sem_sub.san_semester.id, sem_sub.id)
        stu_sub.update_attributes({:group_id=>self.id, :academic_year_id=>ac_year.id, :subject_id=>sem_sub.san_subject.id})
      end
      # Subscribe to classes that are transferred from previous years
      transferred_student_subjects = student.get_to_be_transferred_subjects_for_year(previous_year)
      unless transferred_student_subjects.empty?
        transferred_student_subjects.each do |t_stu_sub|
          # Check if the subject to be transferred is taught in the same period
          sem_num_sum = t_stu_sub.semester_subjects.san_semester.number+semester.number
          # Transfer the subjects from previous academic years
          stu_sub = StudentsSubject.find_or_create_by_student_id_and_academic_year_id_and_semester_subjects_id(student.id, ac_year.id, t_stu_sub.semester_subjects_id)
          stu_sub.update_attributes({:group_id=>self.id, :subject_id=>t_stu_sub.san_subject.id})
          if sem_num_sum%2 == 0
            stu_sub.update_attributes({:san_semester_id=>semester.id})
          end
        end
      end
      student_performance = StudentMilitaryPerformance.find_or_create_by_student_id_and_academic_year_id(student.id, semester.academic_year.id)
      student.estimate_performance_scores(semester.academic_year)
    end
  end

  def get_successful_students_for_year(year, exam_period='c')
    students = Student.find_all_by_group_id(self.id)
    inactive_students = students.select{|a| a.is_active_for_year(year)==false}
    successful_students = students.select{|a| a.get_to_be_transferred_subjects_for_year(year, exam_period).length==0}-inactive_students
    unsuccessful_students = students-successful_students-inactive_students
    return successful_students, unsuccessful_students
  end

  def get_graduation_academic_year
    expected_graduation_year = self.graduation_year.year
    ac_years = AcademicYear.all.select{|a| a.end_date.year==expected_graduation_year}
    return ac_years[0]
  end

  def get_graduating_students
    students = Student.find_all_by_group_id(self.id)
    grad_acad_year = self.get_graduation_academic_year
    successful_students = StudentMilitaryPerformance.find(:all, :conditions=>{:group_id=>self.id, :academic_year_id=>grad_acad_year.id,
                                                                              :n_unfinished_subjects=>0})
    unsuccessful_students = students-successful_students
    return successful_students, unsuccessful_students
  end

  def get_students_to_graduate
    students = Student.find_all_by_group_id(self.id)
    successful_students = students.select{|a| a.get_to_be_transferred_subjects_for_year(self.last_year, 'c').length==0}
    unsuccessful_students = students-successful_students
    return successful_students, unsuccessful_students
  end

  def last_year
    all_years = SanSemester.find_all_by_group_id(self.id).map(&:academic_year).uniq
    all_years.sort!{|a,b| a.start_date<=>b.start_date}
    return all_years.last
  end

  def get_overall_seniority_list
    group_smps = StudentMilitaryPerformance.find(:all, :conditions=>{:group_id=>self.id, :is_active=>true,
                                                                     :academic_year_id=>self.last_year.id},
                                                 :order=>"case when cum_seniority is null then 100 else cum_seniority end asc")
    undef_students = Array.new
    sorted_students = Array.new
    require 'unicode'
    require 'jcode'

    group_smps.each do |smp|
      if smp.success_type==0 or !smp.student.is_active_for_year(self.last_year)
        break
      end
      stu_info = {:gpa=>smp.cum_gpa, :total_sum=>smp.cum_points, :uni_gpa=>smp.cum_univ_gpa,
                  :full_name=>Unicode.upcase(smp.student.full_name.tr('άέήίόύώ','αεηιουω')), :mil_gpa=>smp.cum_mil_gpa,:mil_p_gpa=>smp.cum_mil_p_gpa,
                  :n_unfinished_subjects=>smp.cum_n_unfinished_subjects, :father=>Unicode.upcase(smp.student.fathers_first_name.tr('ΎΌΈΆΊΉάέήίόύώ','ΥΟΕΑΙΗαεηιουω')),
                  :gender=>smp.student.gender, :id=>smp.student.id, :admission_no=>smp.student.admission_no,
                  :seniority=>smp.cum_seniority
      }
      sorted_students.push(stu_info)
    end
    return sorted_students, undef_students
  end

  def seniority_list_for_year(year, exam_period='c', student_id=nil)

    # Sort by unfinished subjects and then gpa and then uni_gpa

  end

  def get_seniority_list_for_year(year, exam_period='c')
    unsorted_students = Array.new
    sorted_students = Array.new
    sorted_successful_students = Array.new
    sorted_successful_september_students = Array.new
    sorted_unsuccessful_students = Array.new
    undef_students = Array.new
    require 'unicode'
    require 'jcode'
    all_students = Student.find_all_by_group_id(self.id, true)

    all_students.each do |stu|
      gpa, points, uni_gpa, mil_gpa, mil_p_grade, uni_points, mil_points, mil_performance_points = stu.get_gpa_and_points_for_year(year, exam_period)
      n_unfinished_subjects = stu.get_to_be_transferred_subjects_for_year(year, exam_period).length
      if n_unfinished_subjects>0
        success_type = 0
      else
        if stu.get_to_be_transferred_subjects_for_year(year,'b').length==0
          success_type = 2
        else
          if exam_period=='b'
            success_type = 0
          else
            success_type = 1
          end
        end
      end
      stu_info = {:gpa=>gpa, :total_sum=>points, :uni_gpa=>uni_gpa, :full_name=>Unicode.upcase(stu.full_name.tr('ΎΌΈΆΊΉάέήίόύώ','ΥΟΕΑΗΙαεηιουω')),
                  :mil_gpa=>mil_gpa, :mil_p_gpa=>mil_p_grade, :n_unfinished_subjects=>n_unfinished_subjects,
                  :father=>Unicode.upcase(stu.fathers_first_name.tr('ΎΌΈΆΊΉάέήίόύώ','ΥΟΕΑΗΙαεηιουω')),
                  :gender=>stu.gender, :id=>stu.id, :admission_no=>stu.admission_no, :success_type=>success_type,
                  :seniority=>nil}
      if points.nil? or uni_gpa.nil? or mil_gpa.nil? or !stu.is_active_for_year(year)
        undef_students.push(stu_info)
        next
      else
        unsorted_students.push(stu_info)
      end
    end

    # Sort by unfinished subjects and then total number of points and then uni_gpa
    sorted_students = unsorted_students.sort {|a,b|
      a[:success_type]==b[:success_type] ?
          (a[:n_unfinished_subjects]==b[:n_unfinished_subjects] ?
              ((b[:total_sum] - a[:total_sum]).abs < 0.001 ?
                  ((b[:uni_gpa]-a[:uni_gpa]).abs < 0.001 ?
                      ((b[:mil_gpa] - a[:mil_gpa]).abs < 0.001 ?
                          b[:full_name]<=>a[:full_name] : b[:mil_gpa]<=>a[:mil_gpa]) : b[:uni_gpa] <=> a[:uni_gpa]) : b[:total_sum] <=> a[:total_sum]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]) : b[:success_type]<=>a[:success_type]}

    seniority = 1
    sorted_students.each do |stu|
      stu[:seniority] = seniority
      if stu[:success_type]==2
        sorted_successful_students.push(stu)
      elsif stu[:success_type]==1
        sorted_successful_september_students.push(stu)
      elsif stu[:success_type]==0
        sorted_unsuccessful_students.push(stu)
      end
      seniority += 1
    end

    if undef_students.length>0
      undef_students.sort! {|a,b| a[:full_name] <=> b[:full_name]}
    end

    return sorted_successful_students, sorted_successful_september_students, sorted_unsuccessful_students, undef_students
  end

  def estimate_seniority_batch(year, exam_period='c')
    all_students = Student.find_all_by_group_id(self.id, true)
    unsorted_students = Array.new
    require 'unicode'
    require 'jcode'
    all_students.each do |stu|
      gpa, points, uni_gpa, mil_gpa, mil_p_grade, uni_points, mil_points, mil_performance_points = stu.get_gpa_and_points_for_year(year, exam_period)
      n_unfinished_subjects = stu.get_to_be_transferred_subjects_for_year(year, exam_period).length
      if n_unfinished_subjects>0
        success_type = 0
      else
        if stu.get_to_be_transferred_subjects_for_year(year,'b').length==0
          success_type = 2
        else
          success_type = 1
        end
      end
      smp = StudentMilitaryPerformance.find_or_create_by_student_id_and_academic_year_id(stu.id, year.id)
      smp.update_attributes({:group_id => self.id, :gpa=>gpa, :grade=>mil_p_grade, :univ_gpa=>uni_gpa, :mil_gpa=>mil_gpa,
                             :points=>points, :univ_points=>uni_points, :mil_points=>mil_points, :mil_p_points=>mil_performance_points,
                             :n_unfinished_subjects=>n_unfinished_subjects, :success_type=>success_type})

      # Take care of cases when the grades have not been correctly estimated
      if points.nil? or uni_gpa.nil? or mil_gpa.nil?
        next
      else
        stu_info = {:total_sum=>points, :uni_gpa=>uni_gpa, :full_name=>Unicode.upcase(stu.full_name.tr('άέήίόύώ','αεηιουω')),
                  :mil_gpa=>mil_gpa,:mil_p_gpa=>mil_p_grade, :n_unfinished_subjects=>n_unfinished_subjects,
                  :id=>stu.id, :admission_no=>stu.admission_no, :success_type=>success_type}
        unsorted_students.push(stu_info)
      end
    end
    # Sort by unfinished subjects and then total number of points and then uni_gpa
    sorted_successful_students = unsorted_students.sort {|a,b|
        a[:success_type]==b[:success_type] ?
            (a[:n_unfinished_subjects]==b[:n_unfinished_subjects] ?
            ((b[:total_sum] - a[:total_sum]).abs < 0.001 ?
            ((b[:uni_gpa]-a[:uni_gpa]).abs < 0.001 ?
                ((b[:mil_gpa] - a[:mil_gpa]).abs < 0.001 ?
                    b[:full_name]<=>a[:full_name] : b[:mil_gpa]<=>a[:mil_gpa]) : b[:uni_gpa] <=> a[:uni_gpa]) : b[:total_sum] <=> a[:total_sum]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]) : b[:success_type]<=>a[:success_type]}

    seniority = 1
    sorted_successful_students.each do |stu|
      smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(stu[:id], year.id)
      smp.update_attributes({:seniority=>seniority})
      seniority += 1
    end
    sorted_successful_students.length
  end


  def estimate_cum_seniority_batch
    all_students = Student.find_all_by_group_id(self.id, true)
    unsorted_students = Array.new
    l_year = self.last_year
    require 'unicode'
    require 'jcode'
    all_students.each do |stu|
      cum_gpa, cum_points, cum_uni_gpa, cum_mil_gpa, cum_mil_p_grade, cum_uni_points, cum_mil_points, cum_mil_performance_points = stu.get_total_gpa_and_points
      gpa, points, uni_gpa, mil_gpa, mil_p_grade, uni_points, mil_points, mil_performance_points = stu.get_gpa_and_points_for_year(l_year, 'c')
      cum_n_unfinished_subjects = stu.get_total_number_of_transferred_subjects('b')
      n_unfinished_subjects = stu.get_to_be_transferred_subjects_for_year(l_year).length
      if n_unfinished_subjects>0
        success_type = 0
      else
        success_type = 1
      end
      smp = StudentMilitaryPerformance.find_or_create_by_student_id_and_academic_year_id(stu.id, l_year.id)
      smp.update_attributes({:cum_gpa=>cum_gpa, :cum_mil_p_gpa=>cum_mil_p_grade, :cum_univ_gpa=>cum_uni_gpa, :cum_mil_gpa=>cum_mil_gpa,
                             :cum_points=>cum_points, :mil_p_points=>cum_mil_performance_points,
                             :n_unfinished_subjects=>n_unfinished_subjects, :cum_n_unfinished_subjects=>cum_n_unfinished_subjects})

      # Take care of cases when the grades have not been correctly estimated
      if cum_points.nil? or cum_uni_gpa.nil? or cum_mil_gpa.nil? or gpa.nil? or points.nil?
        next
      else
        stu_info = {:total_sum=>cum_points, :uni_gpa=>cum_uni_gpa, :full_name=>Unicode.upcase(stu.full_name.tr('άέήίόύώ','αεηιουω')),
                    :mil_gpa=>cum_mil_gpa,:mil_p_gpa=>cum_mil_p_grade, :n_unfinished_subjects=>n_unfinished_subjects,
                    :cum_n_unfinished_subjects=>cum_n_unfinished_subjects, :id=>stu.id, :admission_no=>stu.admission_no,
                    :success_type=>success_type}
        unsorted_students.push(stu_info)
      end
    end
    # Sort by unfinished subjects and then total number of points and then uni_gpa
    sorted_successful_students = unsorted_students.sort {|a,b|
      a[:success_type]==b[:success_type] ?
          (a[:n_unfinished_subjects]==b[:n_unfinished_subjects] ?
            (a[:cum_n_unfinished_subjects]==b[:cum_n_unfinished_subjects] ?
              ((b[:total_sum] - a[:total_sum]).abs < 0.001 ?
                  ((b[:uni_gpa]-a[:uni_gpa]).abs < 0.001 ?
                      ((b[:mil_gpa] - a[:mil_gpa]).abs < 0.001 ?
                          b[:full_name]<=>a[:full_name] : b[:mil_gpa]<=>a[:mil_gpa]) : b[:uni_gpa] <=> a[:uni_gpa]) : b[:total_sum] <=> a[:total_sum]) : a[:cum_n_unfinished_subjects]<=>b[:cum_n_unfinished_subjects]) :a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]) : b[:success_type]<=>a[:success_type]}

    seniority = 1
    sorted_successful_students.each do |stu|
      smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(stu[:id], l_year.id)
      smp.update_attributes({:cum_seniority=>seniority})
      seniority += 1
    end
    sorted_successful_students.length
  end
end
