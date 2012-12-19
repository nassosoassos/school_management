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

    def estimate_seniority_batch(year)
      all_students = Student.find_all_by_group_id(self.id, true)
      all_students.each do |stu|
        if stu.is_active_for_year(year)
          stu.estimate_performance_scores(year)
        end
      end
      return all_students.length
    end

    def graduate(graduation_date)
      students = Student.find_all_by_group_id_and_is_active(self.id, true)
      students.each do |stu|
        if stu.get_to_be_transferred_subjects_for_year(self.last_year).length==0
          stu.graduate(graduation_date, nil)
        else

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
      self.update_attributes({:graduated=>false, :graduation_leave_date=>nil})
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
         (stu_smp_higher.cum_points.nil? or stu_smp_higher.cum_n_unfinished_subjects>stu_smp.cum_n_unfinished_subjects or
         (stu_smp_higher.cum_n_unfinished_subjects==stu_smp.cum_n_unfinished_subjects and 
          ((stu_smp.cum_points-stu_smp_higher.cum_points > 0.001) or 
         ((stu_smp.cum_points-stu_smp_higher.cum_points).abs<0.001 and (stu_smp.cum_univ_gpa-stu_smp_higher.cum_univ_gpa>0.001 or 
         ((stu_smp.cum_univ_gpa-stu_smp_higher.cum_univ_gpa).abs<0.001 and stu_smp_higher.cum_mil_gpa<stu_smp.cum_mil_gpa))))))  
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
           (stu_smp.cum_points.nil? or stu_smp_lower.cum_n_unfinished_subjects<stu_smp.cum_n_unfinished_subjects or
           (stu_smp_lower.cum_n_unfinished_subjects==stu_smp.cum_n_unfinished_subjects and 
            ((stu_smp_lower.cum_points-stu_smp.cum_points > 0.001) or 
           ((stu_smp.cum_points-stu_smp_lower.cum_points).abs<0.001 and (stu_smp_lower.cum_univ_gpa-stu_smp_lower.cum_univ_gpa>0.001 or 
           ((stu_smp.cum_univ_gpa-stu_smp_lower.cum_univ_gpa).abs<0.001 and stu_smp_lower.cum_mil_gpa>stu_smp.cum_mil_gpa))))))  
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
      successful_students = students.select{|a| a.get_to_be_transferred_subjects_for_year(year, exam_period).length==0}
      unsuccessful_students = students-successful_students
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
      successful_students, unsuccessful_students = get_students_to_graduate
      unsorted_successful_students = Array.new
      unsorted_unsuccessful_students = Array.new
      undef_students = Array.new
      successful_students.each do |stu|
        n_unfinished_subjects = stu.get_total_number_of_transferred_subjects('b')
        total_gpa, total_sum, uni_gpa, mil_gpa, mil_p_gpa = stu.get_total_gpa_and_points('c')      
        stu_info = {:gpa=>total_gpa, :total_sum=>total_sum, :uni_gpa=>uni_gpa, :full_name=>stu.full_name,
          :mil_gpa=>mil_gpa,:mil_p_gpa=>mil_p_gpa, :n_unfinished_subjects=>n_unfinished_subjects, 
          :father=>stu.fathers_first_name, :gender=>stu.gender, :id=>stu.id, :admission_no=>stu.admission_no}
        if total_gpa!=nil and uni_gpa!=nil
          unsorted_successful_students.push(stu_info)
        else
          undef_students.push(stu_info)
        end
      end
      # Sort by unfinished subjects and then gpa and then uni_gpa
      sorted_students = unsorted_successful_students.sort {|a,b| a[:n_unfinished_subjects]==b[:n_unfinished_subjects]? ((b[:total_sum] - a[:total_sum]).abs < 0.001? b[:uni_gpa] <=> a[:uni_gpa] : b[:total_sum] <=> a[:total_sum]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]}
      if undef_students.length>0
        undef_students.sort! {|a,b| a[:full_name] <=> b[:full_name]}
      end

      return sorted_students, undef_students
    end

    def seniority_list_for_year(year, exam_period='c', student_id=nil)

      # Sort by unfinished subjects and then gpa and then uni_gpa

    end

    def get_seniority_list_for_year(year, exam_period='c')
      successful_students, unsuccessful_students = get_successful_students_for_year(year,'b')

      unsorted_successful_students = Array.new
      unsorted_successful_september_students = Array.new
      unsorted_unsuccessful_students = Array.new
      undef_students = Array.new
      successful_students.each do |stu|
        n_unfinished_subjects = stu.get_to_be_transferred_subjects_for_year(year, exam_period).length
        total_gpa, total_sum, uni_gpa, mil_gpa, mil_p_gpa = stu.get_gpa_and_points_for_year(year, exam_period)      
        stu_info = {:gpa=>total_gpa, :total_sum=>total_sum, :uni_gpa=>uni_gpa, :full_name=>stu.full_name,
          :mil_gpa=>mil_gpa,:mil_p_gpa=>mil_p_gpa, :n_unfinished_subjects=>n_unfinished_subjects, 
          :father=>stu.fathers_first_name, :gender=>stu.gender, :id=>stu.id, :admission_no=>stu.admission_no}
        if total_gpa!=nil and uni_gpa!=nil
          unsorted_successful_students.push(stu_info)
        else
          undef_students.push(stu_info)
        end
      end

      unsuccessful_students.each do |stu|
        n_unfinished_subjects = stu.get_to_be_transferred_subjects_for_year(year, exam_period).length
        total_gpa, total_sum, uni_gpa, mil_gpa, mil_p_gpa = stu.get_gpa_and_points_for_year(year, exam_period)      
        stu_info = {:gpa=>total_gpa, :total_sum=>total_sum, :uni_gpa=>uni_gpa, :full_name=>stu.full_name,
          :mil_gpa=>mil_gpa,:mil_p_gpa=>mil_p_gpa, :n_unfinished_subjects=>n_unfinished_subjects, 
          :father=>stu.fathers_first_name, :gender=>stu.gender, :id=>stu.id, :admission_no=>stu.admission_no}
        if total_gpa!=nil and uni_gpa!=nil
          if n_unfinished_subjects==0
            unsorted_successful_september_students.push(stu_info)
          else
            unsorted_unsuccessful_students.push(stu_info)
          end
        else
          undef_students.push(stu_info)
        end
      end

      # Sort by unfinished subjects and then gpa and then uni_gpa
      sorted_successful_students = unsorted_successful_students.sort {|a,b| a[:n_unfinished_subjects]==b[:n_unfinished_subjects]? ((b[:total_sum] - a[:total_sum]).abs < 0.001 ? b[:uni_gpa] <=> a[:uni_gpa] : b[:total_sum] <=> a[:total_sum]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]}
      sorted_successful_september_students = unsorted_successful_september_students.sort {|a,b| a[:n_unfinished_subjects]==b[:n_unfinished_subjects]? ((b[:total_sum] - a[:total_sum]).abs < 0.001 ? b[:uni_gpa] <=> a[:uni_gpa] : b[:total_sum] <=> a[:total_sum]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]}
      sorted_unsuccessful_students = unsorted_unsuccessful_students.sort {|a,b| a[:n_unfinished_subjects]==b[:n_unfinished_subjects]? ((b[:total_sum] - a[:total_sum]).abs < 0.001 ? b[:uni_gpa] <=> a[:uni_gpa] : b[:total_sum] <=> a[:total_sum]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]}

      if undef_students.length>0
        undef_students.sort! {|a,b| a[:full_name] <=> b[:full_name]}
      end

      return sorted_successful_students, sorted_successful_september_students, sorted_unsuccessful_students, undef_students
    end
end
