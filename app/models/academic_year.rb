class AcademicYear < ActiveRecord::Base
  has_many :san_semesters

  validates_uniqueness_of :start_date

  def name
    return "#{self.start_date.year}-#{self.end_date.year}"
  end

  def previous
    sorted = AcademicYear.find(:all, :order=>"start_date")
    ind = sorted.index{|a| a.id == self.id}
    previous_ind = ind - 1
    if previous_ind==-1
      return nil
    else 
      return sorted[previous_ind]
    end
  end

  def next
    sorted = AcademicYear.find(:all, :order=>"start_date")
    ind = sorted.index{|a| a.id == self.id}
    next_ind = ind + 1
    if next_ind==sorted.length
      return nil
    else 
      return sorted[next_ind]
    end
  end

  def create_next_year
    all_years = AcademicYear.all
    sel_years = all_years.select{|a| a.start_date.year==self.start_date.year+1 and 
                          a.end_date.year==self.end_date.year+1}
    ac_year = sel_years[0]
    if ac_year.nil?
      ac_year = AcademicYear.new({:start_date=>self.start_date>>12, :end_date=>self.end_date>>12})
      ac_year.save
    end
    return ac_year
  end

  def last
    sorted = AcademicYear.find(:all, :order=>"start_date")
    return sorted.last
  end

  def self.last_with_semesters
    sorted = AcademicYear.find(:all, :order=>"start_date")
    last_active = sorted.pop
    while SanSemester.find_by_academic_year_id(last_active.id).nil?
      last_active = sorted.pop
    end

    # Return the two last academic years with registered semesters
    return last_active, sorted.pop
  end

  def get_graduating_group
    end_year = self.end_date.year
    graduating_groups = Array.new
    groups = Group.all
    groups.each do |g|
      if g.graduation_year.year==end_year
        # There is only one group graduating each year
        return g
      end
    end
    return nil
  end

  def graduates
    # Find the students that graduated this year.
    all_graduates = Student.find(:all, :conditions=>['graduated = ? AND graduation_leave_date > ? AND graduation_leave_date < ?', true, self.start_date, self.end_date]);
  end

  def n_graduates
    # Find the number of graduates for the specific year.
    return graduates.length
  end

  def prev_groups_graduating_students(exam_period='c')
    grad_students = Array.new
    # Find students from previous classes that have not graduated while they should have
    groups = Group.find(:all, :order=>"graduation_year DESC")
    prev_groups = groups.select {|a| a.graduation_year.year<self.end_date.year }
    previous_year = self.previous
    pprevious_year = nil
    if previous_year
      pprevious_year = previous_year.previous
    end

    prev_groups.each do |g|
      prev_group_students = Array.new
      sorted_prev_group_students = Array.new
      g_ac_year = g.get_graduation_academic_year
      if g_ac_year and ((previous_year and g_ac_year.id==previous_year.id) or (pprevious_year and g_ac_year.id==pprevious_year.id))
        suc, not_grad_students = g.get_students_to_graduate
        not_grad_students.each do |ngs|
          if (exam_period=="a" and ngs.get_to_be_transferred_subjects_for_year(self, exam_period).length==0) or (exam_period!="a" and ngs.get_to_be_transferred_subjects_for_year(self, "a").length>0 and ngs.get_to_be_transferred_subjects_for_year(self, @exam_period).length==0) or (!ngs.graduation_leave_date.nil? and ngs.graduation_leave_date > self.start_date and ngs.graduation_leave_date < self.end_date)
	    # The students have fulfilled the requirements to graduate
	    smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(ngs.id, self.id)
	    stu_info = {:gpa=>smp.cum_gpa, :total_sum=>smp.cum_points, :uni_gpa=>smp.cum_univ_gpa,
                  :full_name=>Unicode.upcase(smp.student.full_name.tr('άέήίόύώ','αεηιουω')), :mil_gpa=>smp.cum_mil_gpa,:mil_p_gpa=>smp.cum_mil_p_gpa,
                  :n_unfinished_subjects=>smp.cum_n_unfinished_subjects, :father=>Unicode.upcase(smp.student.fathers_first_name.tr('ΎΌΈΆΊΉάέήίόύώ','ΥΟΕΑΙΗαεηιουω')),
                  :gender=>smp.student.gender, :id=>smp.student.id, :admission_no=>smp.student.admission_no,
                  :seniority=>smp.cum_seniority, :success_type=>1
	    }
            prev_group_students.push(stu_info)
          end
        end
      end
      unless prev_group_students.empty?
	      sorted_prev_group_students = prev_group_students.sort {|a,b|
    	  a[:success_type]==b[:success_type] ?
          (a[:n_unfinished_subjects]==b[:n_unfinished_subjects] ?
            (a[:cum_n_unfinished_subjects]==b[:cum_n_unfinished_subjects] ?
              ((b[:total_sum] - a[:total_sum]).abs < 0.001 ?
                  ((b[:uni_gpa]-a[:uni_gpa]).abs < 0.001 ?
                      ((b[:mil_gpa] - a[:mil_gpa]).abs < 0.001 ?
                          b[:full_name]<=>a[:full_name] : b[:mil_gpa]<=>a[:mil_gpa]) : b[:uni_gpa] <=> a[:uni_gpa]) : b[:total_sum] <=> a[:total_sum]) : a[:cum_n_unfinished_subjects]<=>b[:cum_n_unfinished_subjects]) :a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]) : b[:success_type]<=>a[:success_type]}
      end
      grad_students.push(sorted_prev_group_students)
    end
    return grad_students.flatten
  end

  def graduating_students
    # Find the students that are eligible to graduate this year.
    n_graduating_students = 0
    grad_students = Array.new
    grad_group = get_graduating_group
    current_grad_students = Array.new
    if grad_group
      current_grad_students, non_grad_students = grad_group.get_graduating_students
    end
    grad_students.push(current_grad_students)

    # Find students from previous classes that have not graduated while they should have
    groups = Group.find(:all, :order=>"graduation_year DESC")
    prev_groups = groups.select{|a| a.graduation_year.year<self.end_date.year }
    previous_year = self.previous
    pprevious_year = nil
    if previous_year
      pprevious_year = previous_year.previous
    end

    prev_groups.each do |g|
      g_ac_year = g.get_graduation_academic_year
      if g_ac_year and ((previous_year and g_ac_year.id==previous_year.id) or (pprevious_year and g_ac_year.id==pprevious_year.id))
        grad_students.push(g.get_not_graduated_students)
      end
    end
    return grad_students
  end

  def n_graduating_students
    return graduating_students.flatten.length
  end

  def n_subscribed_students
    students = StudentMilitaryPerformance.find_all_by_academic_year_id_and_is_active(self.id,true).map(&:student_id).uniq
    return students.length
  end
end
