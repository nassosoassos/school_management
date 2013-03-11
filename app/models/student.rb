#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class Student < ActiveRecord::Base

  include CceReportMod

  belongs_to :country
  belongs_to :group
  belongs_to :student_category
  belongs_to :nationality, :class_name => 'Country'
  belongs_to :user,:dependent=>:destroy

  has_one    :immediate_contact
  has_one    :student_previous_data
  has_many   :student_previous_subject_mark
  has_many   :guardians, :foreign_key => 'ward_id', :dependent => :destroy
  has_many   :finance_transactions, :as => :payee
  has_many   :attendances
  has_many   :finance_fees
  has_many   :fee_category ,:class_name => "FinanceFeeCategory"
  has_many   :students_subjects, :foreign_key => 'student_id'
  has_many   :san_subjects ,:through => :students_subjects
  has_many   :student_additional_details
  has_many   :batch_students
  has_many   :subject_leaves
  has_many   :grouped_exam_reports
  has_many   :cce_reports
  has_many   :assessment_scores
  has_many   :exam_scores
  has_many   :previous_exam_scores
  has_many   :student_military_performances, :dependent => :destroy


  named_scope :active, :conditions => { :is_active => true }
  named_scope :with_full_name_only, :select=>"id, CONCAT_WS('',first_name,' ',last_name) AS name,first_name,last_name", :order=>:first_name
  named_scope :with_name_admission_no_only, :select=>"id, CONCAT_WS('',first_name,' ',last_name,' - ',admission_no) AS name,first_name,last_name,admission_no", :order=>:first_name

  named_scope :by_first_name, :order=>'first_name',:conditions => { :is_active => true }

  validates_presence_of :admission_no, :uni_admission_no, :admission_date, :first_name, :last_name, :date_of_birth, :group_id
  validates_uniqueness_of :admission_no, :uni_admission_no
  validates_presence_of :gender, :fathers_first_name
  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,   :allow_blank=>true,
                          :message => "#{t('must_be_a_valid_email_address')}"
  validates_format_of     :admission_no, :with => %r"^[A-ZΑ-Ω0-9/_-]*$"i,
                          :message => "#{t('must_contain_only_letters')}"
  validates_numericality_of :height, :only_integer=>true, :greater_than=>100, :less_than=>250, :allow_nil=>true,
                            :message => "#{t('must_be_height')}"
  validates_numericality_of :weight, :only_integer=>true, :greater_than=>30, :less_than=>150, :allow_nil=>true,
                            :message => "#{t('must_be_weight')}"

  validates_associated :user
  before_validation :create_user_and_validate

  has_attached_file :photo,
                    :styles => {:original=> "125x125#"},
                    :url => "/system/:class/:attachment/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/system/:class/:attachment/:id/:style/:basename.:extension"

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
                                    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }

  def validate
    errors.add(:date_of_birth, "#{t('cant_be_a_future_date')}.") if self.date_of_birth >= Date.today \
      unless self.date_of_birth.nil?
    errors.add(:gender, "#{t('model_errors.student.error2')}.") unless ['m', 'f'].include? self.gender.downcase \
      unless self.gender.nil?
    errors.add(:admission_no, "#{t('model_errors.student.error3')}.") if self.admission_no=='0'
    errors.add(:admission_no, "#{t('should_not_be_admin')}") if self.admission_no.to_s.downcase== 'admin'
  end

  def validate_subject_grades(ac_year)
    stu_subs = StudentsSubject.find_all_by_student_id_and_academic_year_id(self.id, ac_year.id)
    n_transferred_subjects = 0
    n_stu_subs = stu_subs.length
    stu_subs.each do |stu_sub|
      f_gs = finalize_grade_set([stu_sub])
      stud_subs = StudentsSubject.find_all_by_student_id_and_semester_subjects_id(self.id, stu_sub.semester_subjects_id)
      if f_gs[0] and f_gs[0]>=5 and stud_subs.length>1
        # Make sure that this student_subject is not transferred to following years
        stud_subs.each do |ssub|
          if (ssub.san_semester and ssub.san_semester.number>stu_sub.san_semester.number) or
              (ssub.academic_year and ssub.academic_year.start_date>stu_sub.academic_year.start_date)
            ac_year = ssub.academic_year
            if ac_year.nil?
              ac_year = ssub.semester_subjects.san_semester.academic_year
            end
            ssub.destroy
            if ac_year
              estimate_performance_scores(ac_year)
            end
          end
        end
      elsif f_gs.empty? or f_gs[0].nil? or f_gs[0]<5
        # If the student has graduated then this has happened incorrectly.
        if self.graduated
          self.update_attributes({:graduated=>false, :graduation_leave_date=>Date.today})
        end

        # Check whether the subject has been transferred to the following academic year. If not, transfer it.
        next_ac_year = stu_sub.academic_year.next
        n_transferred_subjects += 1
        while next_ac_year and self.is_active_for_year(next_ac_year)
          next_year_semesters = SanSemester.find_all_by_group_id_and_academic_year_id(self.group.id, next_ac_year.id)
          if !next_year_semesters.empty? or (next_ac_year==self.group.get_graduation_academic_year.next and self.group.graduated)
            puts "I am here"
            ssub = StudentsSubject.find_by_student_id_and_academic_year_id_and_semester_subjects_id(
                self.id, next_ac_year.id, stu_sub.semester_subjects_id)
            if ssub.nil?
              ssub = StudentsSubject.new({:student_id=>self.id, :academic_year_id=>next_ac_year.id,
                                          :semester_subjects_id=>stu_sub.semester_subjects_id, :subject_id=>stu_sub.subject_id})
              ssub.save
              next_corresponding_semester = next_year_semesters.select{|a| a.number==stu_sub.san_semester.number+2}
              unless next_corresponding_semester.empty?
                ssub.update_attributes({:san_semester_id=>next_corresponding_semester[0].id})
              end
              self.estimate_performance_scores(next_ac_year)
            end
          end
          next_ac_year = next_ac_year.next
          if self.group.graduated
            if next_ac_year.start_date.year==self.group.last_year.start_date.year+2
              break
            end
          end
        end
      end
    end
    return n_transferred_subjects
  end

  def update_subject_grades(stu_sub, a_grade, b_grade, c_grade)
    # Ensure proper transfer of subjects between semesters when grades are updated
    #         
    # update_subject_grades(stu_sub, a_grade, b_grade, c_grade)
    #
    # Description:
    # Typically, each student's subjects to be transferred to the following academic
    # year are determined when the student's class (group) is subscribed to the first
    # semester of the following year. At that point, subjects for which there is no exam grade above 
    # 5 are transferred to the following academic year.
    # However, if by mistake a subject's grade is not updated in time and is corrected later on,
    # this function ensures that the transferred subjects between semesters as well as the seniority lists 
    # are properly updated.
    #
    # Arguments:
    # stu_sub - ActiveRecord instance of StudentsSubject class. Contains all the information about a particular
    #           subject for a certain semester. A new one is created for each subject that is transferred to a
    #           new semester.
    # a_grade - Grade for the first examination period (January-February)
    # b_grade - Grade for the second examination period (June-July)
    # c_grade - Grade for the third examination period (September)
    updated = false
    if a_grade!=stu_sub.a_grade or b_grade!=stu_sub.b_grade or c_grade!=stu_sub.c_grade
      stu_sub.update_attributes({:a_grade=>a_grade, :b_grade=>b_grade, :c_grade=>c_grade})
      f_gs = finalize_grade_set([stu_sub])
      stud_subs = StudentsSubject.find_all_by_student_id_and_semester_subjects_id(self.id, stu_sub.semester_subjects_id)
      if f_gs[0] and f_gs[0]>=5 and stud_subs.length>1
        # Make sure that this student_subject is not transferred to following years
        stud_subs.each do |ssub|
          if (ssub.san_semester and ssub.san_semester.number>stu_sub.san_semester.number) or
              (ssub.academic_year and ssub.academic_year.start_date>stu_sub.academic_year.start_date)
            ac_year = ssub.academic_year
            if ac_year.nil?
              ac_year = ssub.semester_subjects.san_semester.academic_year
            end
            ssub.destroy
            if ac_year
              estimate_performance_scores(ac_year)
            end
          end
        end
      elsif f_gs.empty? or f_gs[0].nil? or f_gs[0]<5
        # Check whether the subject has been transferred to the following academic year. If not, transfer it.

        # If the student has graduated then this has happened incorrectly.
        if self.graduated
          self.update_attributes({:graduated=>false, :graduation_leave_date=>Date.today})
        end
        next_ac_year = stu_sub.academic_year.next
        while next_ac_year and self.is_active_for_year(next_ac_year)
          next_year_semesters = SanSemester.find_all_by_group_id_and_academic_year_id(self.group.id, next_ac_year.id)
          if !next_year_semesters.empty? or (next_ac_year==self.group.get_graduation_academic_year.next and self.group.graduated)
            ssub = StudentsSubject.find_by_student_id_and_academic_year_id_and_semester_subjects_id(
                self.id, next_ac_year.id, stu_sub.semester_subjects_id)
            if ssub.nil?
              ssub = StudentsSubject.new({:student_id=>self.id, :academic_year_id=>next_ac_year.id,
                                          :semester_subjects_id=>stu_sub.semester_subjects_id, :subject_id=>stu_sub.subject_id})
              ssub.save
              next_corresponding_semester = next_year_semesters.select{|a| a.number==stu_sub.san_semester.number+2}
              unless next_corresponding_semester.empty?
                ssub.update_attributes({:san_semester_id=>next_corresponding_semester[0].id})
              end
              self.estimate_performance_scores(next_ac_year)
            end
          end
          next_ac_year = next_ac_year.next
          if self.group.graduated
            if next_ac_year.start_date.year==self.group.last_year.start_date.year+2
              break
            end
          end
        end
      end
      updated = true
    end
    return updated
  end

  def update_grades_on_group_change(old_group_id)
    new_group_id = self.group.id
    ind = 1
    if old_group_id!=new_group_id
      stu_subs = StudentsSubject.find_all_by_student_id(self.id)
      stu_subs.each do |s|
        new_sem = SanSemester.find_by_number_and_group_id(s.san_semester.number, new_group_id)
        new_orig_sem = SanSemester.find_by_number_and_group_id(s.semester_subjects.san_semester.number, new_group_id)
        new_sem_sub = SemesterSubjects.find_by_subject_id_and_semester_id(s.subject_id, new_orig_sem.id)
        if new_sem_sub.nil?
          sem_subs = SemesterSubjects.find_all_by_subject_id(s.subject_id)
          sem_subs.each do |semsub|
            if semsub.san_semester.group.id==new_group_id
              new_sem_sub = semsub
            end
          end
        end
        puts "Index: " + ind.to_s
        unless new_sem.academic_year.nil? or new_sem.nil? or new_sem_sub.nil?
          begin
            s.update_attributes({:group_id=>new_group_id, :academic_year_id=>new_sem.academic_year.id,
                                 :san_semester_id=>new_sem.id, :semester_subjects_id=>new_sem_sub.id})
          rescue
            puts "Error"
          end
        end
        ind += 1
      end

      # Update military performances
      stumps = StudentMilitaryPerformance.find_all_by_student_id(self.id)
      stumps.each do |stump|
        ac_year = stump.academic_year
        old_sem = SanSemester.find_by_academic_year_id_and_group_id(ac_year.id, old_group_id)
        new_ac_year = SanSemester.find_by_group_id_and_number(new_group_id, old_sem.number).academic_year
        stump.update_attributes({:academic_year_id=>new_ac_year.id, :group_id=>new_group_id})
      end

      # Update seniorities
      new_group_years = SanSemester.find_all_by_group_id(self.group.id).map(&:academic_year).uniq
      new_group_years.each do |yr|
        self.estimate_performance_scores(yr)
        self.group.estimate_seniority(yr, self.id)
      end
      old_group_years = SanSemester.find_all_by_group_id(old_group_id).map(&:academic_year).uniq
      old_group_years.each do |yr|
        self.group.reset_seniority(yr)
        self.group.estimate_seniority_batch(yr)
      end
      self.group.reset_cum_seniority
      self.group.estimate_cum_seniority_batch
    end
  end

  def finalize_grade_set(grade_set_array, exam_period='c')
    grades = Array.new
    grade_set_array.each do |grade_set|
      if grade_set.a_grade != nil
        final_grade = grade_set.a_grade
      elsif grade_set.b_grade != nil
        final_grade = grade_set.b_grade
      end
      if exam_period=='c'
        if grade_set.c_grade != nil
          final_grade = grade_set.c_grade
        end
      end
      grades.push(final_grade)
    end
    return grades
  end

  def total_gpa_and_points
    semesters = SanSemester.find_all_by_group_id(self.group.id)
    academic_years = semesters.map(&:academic_year).uniq

    sum_of_points = 0
    sum_of_gpas = 0
    n_academic_years = 0
    academic_years.each do |ac|
      y_gpa, y_points = get_gpa_and_points_for_year(ac)
      unless y_gpa.nil?
        n_academic_years += 1
        sum_of_points += y_points
        sum_of_gpas += y_gpa
      end
    end
    puts n_academic_years
    puts sum_of_gpas
    puts sum_of_points
    if n_academic_years>0
      return sum_of_gpas.to_f / n_academic_years, sum_of_points.to_f / n_academic_years
    else
      return nil, nil
    end
  end

  def get_transferred_subjects_for_year(year)
    # Transferred subjects for year
    # Compare semester_subject.semester_id with students_subject.semester_id
    year_semesters = SanSemester.find_all_by_academic_year_id_and_group_id(year.id, self.group.id)
    all_subject_grades = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=?',self.id, year.id])
    transferred_subjects = Array.new
    all_subject_grades.each do |s_grade|
      if year_semesters.select{|a| a.id==s_grade.semester_subjects.semester_id}.empty?
        transferred_subjects.push(s_grade)
      end
    end
    return transferred_subjects
  end

  def get_transferred_subjects
    # Find the transferred subjects for the final/current year
    all_semesters = SanSemester.find_all_by_group_id(self.group.id)
    all_semesters_sorted = all_semesters.sort{|a, b| a.number <=> b.number}
    last_academic_year = all_semesters_sorted.last.academic_year
    puts last_academic_year.name
    return get_transferred_subjects_for_year(last_academic_year)
  end

  def get_standard_subjects_for_year(year)
    # Get the set of students_subjects that have not been
    # transferred from previous years
    all_subject_grades = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=?',self.id, year.id])
    return all_subject_grades - self.get_transferred_subjects_for_year(year)
  end

  def get_to_be_transferred_subjects_for_year(year, exam_period='c')
    ungraded_subjects = get_ungraded_subjects_for_year(year, exam_period)
    graded_subjects = get_graded_subjects_for_year(year, exam_period)
    failed_subjects = Array.new
    graded_subjects.each do |g_s|
      f_gs = finalize_grade_set([g_s], exam_period)
      if f_gs[0]<5
        failed_subjects.push(g_s)
      end
    end
    to_be_transferred_subjects = ungraded_subjects + failed_subjects
    return to_be_transferred_subjects
  end

  def get_total_number_of_transferred_subjects(exam_period='b')
    all_years = SanSemester.find_all_by_group_id(self.group.id).map(&:academic_year).uniq
    n_transferred_subjects = 0
    all_years.each do |ac|
      n_transferred_subjects += get_to_be_transferred_subjects_for_year(ac, exam_period).length
    end
    return n_transferred_subjects
  end

  def get_passed_subjects_for_year(year, exam_period='c')
    all_subject_grades = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=?',self.id, year.id])
    return all_subject_grades - self.get_to_be_transferred_subjects_for_year(year, exam_period)
  end

  def get_all_passed_subjects(exam_period='c')
    all_years = SanSemester.find_all_by_group_id(self.group.id).map(&:academic_year).uniq

    all_passed_subject_grades = Array.new
    all_years.each do |year|
      year_subject_grades = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=?',self.id, year.id])
      passed_year_subject_grades = year_subject_grades - self.get_to_be_transferred_subjects_for_year(year, exam_period)
      all_passed_subject_grades += passed_year_subject_grades
    end
    return all_passed_subject_grades
  end

  def get_ungraded_subjects_for_year(year, exam_period='c')
    # Find all subject for which all three possible grades are null
    if exam_period=='c'
      ungraded_subjects = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=? and a_grade IS NULL and b_grade IS NULL and c_grade IS NULL', self.id, year.id])
    elsif exam_period=='b'
      ungraded_subjects = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=? and a_grade IS NULL and b_grade IS NULL', self.id, year.id])
    end
    return ungraded_subjects
  end

  def get_graded_subjects_for_year(year, exam_period='c')
    if exam_period=='c'
      graded_subjects = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=? and (a_grade IS NOT NULL or b_grade IS NOT NULL or c_grade IS NOT NULL)', self.id, year.id])
    elsif exam_period=='b'
      graded_subjects = StudentsSubject.find(:all, :conditions=>['student_id=? and academic_year_id=? and (a_grade IS NOT NULL or b_grade IS NOT NULL)', self.id, year.id])
    end
    return graded_subjects
  end

  def get_total_univ_gpa_and_points(exam_period='c')
    passed_student_subjects = get_all_passed_subjects(exam_period)
    univ_subjects = passed_student_subjects.select{|a| a.san_subject.kind=='University'}

    grades = finalize_grade_set(univ_subjects, exam_period)
    if grades.size>0
      univ_gpa = grades.inject(0.0) { |sum, el| sum + el } / grades.size
      univ_points = univ_gpa*SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group.id).uni_weight
    else
      univ_gpa = nil
      univ_points = nil
    end
    return univ_gpa, univ_points
  end

  def get_total_mil_gpa_and_points(exam_period='c')
    passed_student_subjects = get_all_passed_subjects(exam_period)
    mil_subjects = passed_student_subjects.select{|a| a.san_subject.kind=='Military'}

    grades = finalize_grade_set(mil_subjects, exam_period)
    if grades.size>0
      mil_gpa = grades.inject(0.0) { |sum, el| sum + el } / grades.size
      # Assume that the most recent weights are the valid ones
      mil_points = mil_gpa*SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group.id).mil_weight
    else
      mil_gpa = nil
      mil_points = nil
    end
    return mil_gpa, mil_points
  end

  def get_total_gpa_and_points(exam_period='c')
    uni_gpa, uni_points = get_total_univ_gpa_and_points(exam_period)
    mil_gpa, mil_points = get_total_mil_gpa_and_points(exam_period)

    # Only use the weights specified for the first semester of the 
    # academic year
    last_semester = SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group_id)
    unless last_semester
      last_semester = SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group.id)
    end
    mil_p_weight = last_semester.mil_p_weight.to_f
    mil_p_grades = StudentMilitaryPerformance.find_all_by_student_id(self.id).map(&:grade)
    if mil_p_grades.include?nil
      mil_p_grades.compact!
    end
    if mil_p_grades.blank?
      mil_p_grade = nil
    else
      mil_p_grade = mil_p_grades.inject(0.0) { |sum, el| sum + el } / mil_p_grades.size
    end
    if mil_p_grade
      mil_performance_points = mil_p_weight * mil_p_grade
    else
      mil_performance_points = nil
    end

    sum_of_weights = 0
    points = 0
    if uni_points
      sum_of_weights += last_semester.uni_weight.to_f
      points += uni_points
    end
    if mil_points
      sum_of_weights += last_semester.mil_weight.to_f
      points += mil_points
    end
    if mil_performance_points
      sum_of_weights += mil_p_weight
      points += mil_performance_points
    end
    if sum_of_weights>0
      gpa = points.to_f / sum_of_weights
    else
      gpa = nil
      points = nil
    end

    return [gpa, points, uni_gpa, mil_gpa, mil_p_grade, uni_points, mil_points, mil_performance_points]
  end

  def get_univ_gpa_and_points_for_year(year, exam_period='c')
    passed_student_subjects = get_passed_subjects_for_year(year, exam_period)
    univ_subjects = passed_student_subjects.select{|a| a.san_subject.kind=='University'}
    grades = finalize_grade_set(univ_subjects, exam_period)

    if grades.size > 0
      univ_gpa = grades.inject(0.0) { |sum, el| sum + el } / grades.size
      first_semester = SanSemester.find_by_academic_year_id_and_group_id(year.id, self.group.id)
      unless first_semester
        first_semester = SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group.id)
      end
      univ_points = first_semester.uni_weight  * univ_gpa
      return univ_gpa, univ_points
    else
      return nil, nil
    end
  end

  def get_mil_gpa_and_points_for_year(year, exam_period='c')
    passed_student_subjects = get_passed_subjects_for_year(year, exam_period)
    mil_subjects = passed_student_subjects.select{|a| a.san_subject.kind=='Military'}
    grades = finalize_grade_set(mil_subjects, exam_period)
    if grades.size > 0
      mil_gpa = grades.inject(0.0) { |sum, el| sum + el } / grades.size
      last_semester = SanSemester.find_by_academic_year_id_and_group_id(year.id, self.group.id)
      unless last_semester
        last_semester = SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group.id)
      end
      mil_points = last_semester.mil_weight * mil_gpa
      return mil_gpa, mil_points
    else
      return nil, nil
    end
  end

  def find_next_student(year)
    smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(self.id, year.id)
    unless self.is_active_for_year(year)
      return self
    end
    if smp.nil? or smp.seniority.nil?
      self.estimate_performance_scores(year)
      smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(self.id, year.id)
    end
    if smp.seniority==self.group.n_students(year)
      smp_next = smp
    else
      if smp.seniority.nil?
        smp_next = nil
      else
        smp_next = StudentMilitaryPerformance.find_by_seniority_and_group_id_and_academic_year_id_and_is_active(smp.seniority+1, self.group.id, year.id, true)
      end
    end
    if smp_next
      stu = smp_next.student
    else
      stu = self
    end
    return stu
  end

  def find_previous_student(year)
    smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(self.id, year.id)
    if smp.nil? or smp.seniority.nil?
      self.estimate_performance_scores(year)
      smp = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(self.id, year.id)
    end
    if smp.seniority==1
      smp_prev = smp
    else
      if smp.seniority.nil?
        smp_prev = nil
      else
        smp_prev = StudentMilitaryPerformance.find_by_seniority_and_group_id_and_academic_year_id_and_is_active(smp.seniority-1, self.group.id, year.id, true)
      end
    end
    if smp_prev
      stu = smp_prev.student
    else
      stu = self
    end
    return stu
  end


  def estimate_performance_scores(year)
    gpa, points, uni_gpa, mil_gpa, mil_p_grade, uni_points, mil_points, mil_performance_points = get_gpa_and_points_for_year(year)
    n_unfinished_subjects = get_to_be_transferred_subjects_for_year(year).length

    group_last_year = self.group.last_year
    cum_gpa, cum_points, cum_uni_gpa, cum_mil_gpa, cum_mil_p_grade, cum_uni_points, cum_mil_points, cum_mil_performance_points = get_total_gpa_and_points
    cum_n_unfinished_subjects = get_total_number_of_transferred_subjects('b')
    if n_unfinished_subjects>0
      success_type = 0
    else
      if get_to_be_transferred_subjects_for_year(year,'b').length==0
        success_type = 2
      else
        success_type = 1
      end
    end
    smp = StudentMilitaryPerformance.find_or_create_by_student_id_and_academic_year_id(self.id, year.id)
    smp.update_attributes({:group_id => self.group.id, :gpa=>gpa, :grade=>mil_p_grade, :univ_gpa=>uni_gpa, :mil_gpa=>mil_gpa,
                           :points=>points, :univ_points=>uni_points, :mil_points=>mil_points, :mil_p_points=>mil_performance_points,
                           :n_unfinished_subjects=>n_unfinished_subjects, :success_type=>success_type, :cum_gpa=>cum_gpa,
                           :cum_points=>cum_points, :cum_univ_gpa=>cum_uni_gpa, :cum_mil_gpa=>cum_mil_gpa,
                           :cum_mil_p_gpa=>cum_mil_p_grade, :cum_n_unfinished_subjects=>cum_n_unfinished_subjects})
    unless gpa.nil?
      if !group.graduated or group.graduation_date>year.end_date
        self.group.estimate_seniority(year, self.id)
      end
      self.group.estimate_cum_seniority(self.id)
    end
  end

  def get_gpa_and_points_for_year(year, exam_period='c')
    uni_gpa, uni_points = get_univ_gpa_and_points_for_year(year, exam_period)
    mil_gpa, mil_points = get_mil_gpa_and_points_for_year(year, exam_period)

    # Only use the weights specified for the first semester of the 
    # academic year
    first_semester = SanSemester.find_by_academic_year_id_and_group_id(year.id, self.group_id)
    unless first_semester
      first_semester = SanSemester.find_by_academic_year_id_and_group_id(self.group.last_year.id, self.group.id)
    end
    mil_p_weight = first_semester.mil_p_weight.to_f
    mil_perf = StudentMilitaryPerformance.find_by_student_id_and_academic_year_id(self.id, year.id)
    mil_p_grade = nil
    if mil_perf
      mil_p_grade = mil_perf.grade
    end
    if mil_p_grade
      mil_performance_points = mil_p_weight * mil_p_grade
    else
      mil_performance_points = nil
    end

    sum_of_weights = 0
    points = 0
    if uni_gpa
      sum_of_weights += first_semester.uni_weight.to_f
      points += uni_points
    end
    if mil_gpa
      sum_of_weights += first_semester.mil_weight.to_f
      points += mil_points
    end
    if mil_performance_points
      sum_of_weights += mil_p_weight
      points += mil_performance_points
    end
    if sum_of_weights>0
      gpa = points.to_f / sum_of_weights
    else
      gpa = nil
      points = nil
    end

    return [gpa, points, uni_gpa, mil_gpa, mil_p_grade, uni_points, mil_points, mil_performance_points]
  end

  def gpa_for_year(year, kind)

    student_semesters = SanSemester.find_all_by_academic_year_id_and_group_id(year.map(&:id), self.group_id)

    uni_sum = 0
    mil_sum = 0
    n_mil_p_semesters = 0
    mil_p_sum = 0
    weighted_uni_sum = 0
    weighted_mil_sum = 0
    weighted_mil_p_sum = 0
    uni_weights_sum = 0
    mil_weights_sum = 0
    mil_p_weights_sum = 0
    n_mil_subs = 0
    n_uni_subs = 0
    n_mil_p_grades = 0
    tot_uni_subs = 0
    tot_mil_subs = 0
    tot_mil_p_grades = 0
    n_unfinished_subjects = 0

    student_semesters.each do |semester|
      mil_weight = semester.mil_weight
      uni_weight = semester.uni_weight
      mil_p_weight = semester.mil_p_weight
      student_semester_grades = StudentsSubject.find_all_by_san_semester_id_and_student_id(semester.id, self.id)
      uni_semester_grades = Array.new
      mil_semester_grades = Array.new
      student_semester_grades.each do |s|
        if SanSubject.find(s.subject_id).kind=='University'
          uni_semester_grades.push(s)
        else
          mil_semester_grades.push(s)
        end
      end
      if kind=='all' or kind=='University'
        uni_grade_set = self.finalize_grade_set(uni_semester_grades)
        n_uni_subs = uni_grade_set.nitems
        low_grades = uni_grade_set.select {|g| g!=nil and g<5 }
        n_unfinished_subjects += low_grades.length
        cur_sum = uni_grade_set.compact.inject(0,:+)
        weighted_uni_sum += cur_sum*uni_weight.to_f
        uni_sum += cur_sum
        uni_weights_sum += uni_weight*n_uni_subs
        tot_uni_subs += n_uni_subs
      end
      if kind=='all' or kind=='Military'
        mil_grade_set = self.finalize_grade_set(mil_semester_grades)
        n_mil_subs = mil_grade_set.nitems
        low_grades = mil_grade_set.select {|g| g!=nil and g<5 }
        n_unfinished_subjects += low_grades.length
        cur_sum = mil_grade_set.compact.inject(0,:+)
        weighted_mil_sum += cur_sum*mil_weight.to_f
        mil_sum += cur_sum
        mil_weights_sum += mil_weight*n_mil_subs
        tot_mil_subs += n_mil_subs
      end
    end
    year.each do |y|
      if kind=='all' or kind=='MilitaryPerformance'
        mil_p_weight = SanSemester.find_by_group_id_and_academic_year_id(self.group.id, y.id).mil_p_weight
        # Estimate average military performance
        student_mil_performance = StudentMilitaryPerformance.find_by_academic_year_id_and_student_id(y.id, self.id)
        if student_mil_performance and student_mil_performance.grade
          n_mil_p_semesters += 1
          mil_p_sum += student_mil_performance.grade
          mil_p_weights_sum += mil_p_weight
          weighted_mil_p_sum += student_mil_performance.grade*mil_p_weight
        end
      end
    end

    if kind=='University'

      if tot_uni_subs>0
        return uni_sum/tot_uni_subs.to_f, uni_sum
      else
        return nil, nil
      end
    elsif kind=='Military'
      if tot_uni_subs>0
        return mil_sum/tot_mil_subs.to_f, mil_sum
      else
        return nil, nil
      end
    elsif kind=='MilitaryPerformance'
      if n_mil_p_semesters>0
        return mil_p_sum/n_mil_p_semesters.to_f, mil_p_sum
      else
        return nil, nil
      end
    else
      if tot_uni_subs>0
        uni_gpa = weighted_uni_sum/uni_weights_sum.to_f
        # This is just in case the weights per semester change (It shouldn't happen)
        avg_uni_weight = uni_weights_sum.to_f / tot_uni_subs
        total_uni_sum = uni_gpa * avg_uni_weight
      else
        uni_gpa = nil
        total_uni_sum = 0
        avg_uni_weight = 0
      end
      if tot_mil_subs>0
        mil_gpa = weighted_mil_sum / mil_weights_sum.to_f
        avg_mil_weight = mil_weights_sum.to_f / tot_mil_subs.to_f
        total_mil_sum = mil_gpa * avg_mil_weight
      else
        mil_gpa = nil
        total_mil_sum = 0
        avg_mil_weight = 0
      end
      if n_mil_p_semesters>0
        mil_p_gpa = weighted_mil_p_sum / mil_p_weights_sum.to_f
        avg_mil_p_weight = mil_p_weights_sum / n_mil_p_semesters.to_f
        total_mil_p_sum = mil_p_gpa * avg_mil_p_weight
      else
        mil_p_gpa = nil
        total_mil_p_sum = 0
        avg_mil_p_weight = 0
      end
      total_sum = total_mil_sum + total_uni_sum + total_mil_p_sum
      if total_sum>0
        total_gpa = total_sum/(avg_mil_p_weight + avg_uni_weight + avg_mil_weight)
      else
        total_gpa = nil
        n_unfinished_subjects = nil
      end

      return total_gpa, total_sum, uni_gpa, mil_gpa, mil_p_gpa, n_unfinished_subjects
    end
  end

  def subscribe_to_semester(semester)

  end

  def create_user_and_validate
    if self.new_record? or self.user_id.nil?
      user_record = self.build_user
      user_record.first_name = self.first_name
      user_record.last_name = self.last_name
      user_record.username = self.admission_no.to_s.gsub(/[^a-zA-Z0-9]+/,'')
      user_record.password = user_record.username + "123"
      user_record.role = 'Student'
      user_record.email = self.email.blank? ? "" : self.email.to_s
      check_user_errors(user_record)
      return false unless errors.blank?
    else
      self.user.role = "Student"
      changes_to_be_checked = ['admission_no','first_name','last_name','email','immediate_contact_id']
      check_changes = self.changed & changes_to_be_checked
      unless check_changes.blank?
        self.user.username = self.admission_no.to_s.gsub(/[^a-zA-Z0-9]+/,'') if check_changes.include?('admission_no')
        self.user.first_name = self.first_name if check_changes.include?('first_name')
        self.user.last_name = self.last_name if check_changes.include?('last_name')
        self.user.email = self.email if check_changes.include?('email')
        check_user_errors(self.user)
      end

      if check_changes.include?('immediate_contact_id') or check_changes.include?('admission_no')
        Guardian.shift_user(self)
      end

    end
    self.email = "" if self.email.blank?
    return false unless errors.blank?
  end

  def check_user_errors(user)
    unless user.valid?
      user.errors.each{|attr,msg| errors.add(attr.to_sym,"#{msg}")}
    end
    return false unless user.errors.blank?
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def full_name
    "#{last_name} #{first_name} #{middle_name}"
  end

  def is_active_for_year(year)
    if self.is_active
      return true
    else
      if (self.graduated or (not self.is_active)) and self.graduation_leave_date < year.end_date
        return false
      else
        return true
      end
    end
  end

  def gender_as_text
    return 'Male' if gender.downcase == 'm'
    return 'Female' if gender.downcase == 'f'
    nil
  end

  def graduate(date, details)
    if details
      description = "Αποφοίτησε - " + details
    else
      description = "Αποφοίτησε"
    end
    self.update_attributes({:is_active=>false, :graduated=>true, :graduation_leave_date=>date, :status_description=>description})
  end

  def revert_graduation
    self.update_attributes({:is_active=>true, :graduated=>false, :graduation_leave_date=>nil, :status_description=>nil})
  end

  def deactivate(date, details)
    if details
      description = "Αποχώρησε - " + details
    else
      description = "Αποχώρησε"
    end
    self.update_attributes({:is_active=>false, :graduation_leave_date=>date, :status_description=>description})
    group_years = SanSemester.find_all_by_group_id(self.group.id).map(&:academic_year).uniq

    # Update class seniority to reflect the changes
    group_years.each do |y|
      if y.end_date > date
        smps = StudentMilitaryPerformance.find_all_by_student_id_and_academic_year_id(self.id, y.id)
        smps.each do |sm|
          sm.update_attributes({:is_active=>false})
        end
        self.group.reset_seniority(y)
        self.group.estimate_seniority_batch(y)
        self.group.reset_cum_seniority
        self.group.estimate_cum_seniority_batch
      end
    end
  end

  def graduated_batches
    self.batch_students.map{|bt| bt.batch}
  end

  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def immediate_contact
    Guardian.find(self.immediate_contact_id) unless self.immediate_contact_id.nil?
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end

  def next_student
    next_st = self.batch.students.first(:conditions => "id > #{self.id}", :order => "id ASC")
    next_st ||= batch.students.first(:order => "id ASC")
  end

  def previous_student
    prev_st = self.batch.students.first(:conditions => "id < #{self.id}", :order => "admission_no DESC")
    prev_st ||= batch.students.first(:order => "id DESC")
    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def previous_fee_student(date)
    fee = FinanceFee.first(:conditions => "student_id < #{self.id} and fee_collection_id = #{date}", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id',:order => "student_id DESC")
    prev_st = fee.student unless fee.blank?
    fee ||= FinanceFee.first(:conditions=>"fee_collection_id = #{date}", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id',:order => "student_id DESC")
    prev_st ||= fee.student unless fee.blank?
    #    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def next_fee_student(date)

    fee = FinanceFee.first(:conditions => "student_id > #{self.id} and fee_collection_id = #{date}", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id', :order => "student_id ASC")
    next_st = fee.student unless fee.nil?
    fee ||= FinanceFee.first(:conditions=>"fee_collection_id = #{date}", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id',:order => "student_id ASC")
    next_st ||= fee.student unless fee.nil?
    #    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def finance_fee_by_date(date)
    FinanceFee.find_by_fee_collection_id_and_student_id(date.id,self.id)
  end

  def check_fees_paid(date)
    particulars = date.fees_particulars(self)
    total_fees=0
    financefee = date.fee_transactions(self.id)
    batch_discounts = BatchFeeCollectionDiscount.find_all_by_finance_fee_collection_id(date.id)
    student_discounts = StudentFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(date.id,self.id)
    category_discounts = StudentCategoryFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(date.id,self.student_category_id)
    total_discount = 0
    total_discount += batch_discounts.map{|s| s.discount}.sum unless batch_discounts.nil?
    total_discount += student_discounts.map{|s| s.discount}.sum unless student_discounts.nil?
    total_discount += category_discounts.map{|s| s.discount}.sum unless category_discounts.nil?
    if total_discount > 100
      total_discount = 100
    end
    particulars.map { |s|  total_fees += s.amount.to_f}
    total_fees -= total_fees*(total_discount/100)
    paid_fees_transactions = FinanceTransaction.find(:all,:select=>'amount,fine_amount',:conditions=>"FIND_IN_SET(id,\"#{financefee.transaction_id}\")") unless financefee.nil?
    paid_fees = 0
    paid_fees_transactions.map { |m| paid_fees += (m.amount.to_f - m.fine_amount.to_f) } unless paid_fees_transactions.nil?
    amount_pending = total_fees.to_f - paid_fees.to_f
    if amount_pending == 0
      return true
    else
      return false
    end

    #    unless particulars.nil?
    #      return financefee.check_transaction_done unless financefee.nil?
    #
    #    else
    #      return false
    #    end
  end

  def has_retaken_exam(subject_id)
    retaken_exams = PreviousExamScore.find_all_by_student_id(self.id)
    if retaken_exams.empty?
      return false
    else
      exams = Exam.find_all_by_id(retaken_exams.collect(&:exam_id))
      if exams.collect(&:subject_id).include?(subject_id)
        return true
      end
      return false
    end

  end

  def check_fee_pay(date)
    date.finance_fees.first(:conditions=>"student_id = #{self.id}").is_paid
  end

  def self.next_admission_no
    '' #stub for logic to be added later.
  end

  def get_fee_strucure_elements(date)
    elements = FinanceFeeStructureElement.get_student_fee_components(self,date)
    elements[:all] + elements[:by_batch] + elements[:by_category] + elements[:by_batch_and_category]
  end

  def total_fees(particulars)
    total = 0
    particulars.each do |fee|
      total += fee.amount
    end
    total
  end

  def has_associated_fee_particular?(fee_category)
    status = false
    status = true if fee_category.fee_particulars.find_all_by_admission_no(admission_no).count > 0
    status = true if student_category_id.present? and fee_category.fee_particulars.find_all_by_student_category_id(student_category_id).count > 0
    return status
  end

  def archive_student(status)
    self.update_attributes(:is_active => false, :status_description => status)
    student_attributes = self.attributes
    student_attributes["former_id"]= self.id
    student_attributes.delete "id"
    student_attributes.delete "has_paid_fees"
    student_attributes.delete "user_id"
    student_attributes.delete "created_at"
    archived_student = ArchivedStudent.new(student_attributes)
    archived_student.photo = self.photo
    if archived_student.save
      guardian = self.guardians
      self.user.destroy unless self.user.blank?
      self.destroy
      guardian.each do |g|
        g.archive_guardian(archived_student.id)
      end
      #
      #      student_exam_scores = ExamScore.find_all_by_student_id(self.id)
      #      student_exam_scores.each do |s|
      #        exam_score_attributes = s.attributes
      #        exam_score_attributes.delete "id"
      #        exam_score_attributes.delete "student_id"
      #        exam_score_attributes["student_id"]= archived_student.id
      #        ArchivedExamScore.create(exam_score_attributes)
      #        s.destroy
      #      end
      #
    end

  end

  def check_dependency
    return true if self.finance_transactions.present? or self.graduated_batches.present? or self.attendances.present? or self.finance_fees.present?
    return true if FedenaPlugin.check_dependency(self,"permanant").present?
    return false
  end

  def former_dependency
    plugin_dependencies = FedenaPlugin.check_dependency(self,"former")
  end

  def assessment_score_for(indicator_id,exam_id,batch_id)
    assessment_score = self.assessment_scores.find(:first, :conditions => { :student_id => self.id,:descriptive_indicator_id=>indicator_id,:exam_id=>exam_id,:batch_id=>batch_id })
    assessment_score.nil? ? assessment_scores.build(:descriptive_indicator_id=>indicator_id,:exam_id=>exam_id,:batch_id=>batch_id) : assessment_score
  end
  def observation_score_for(indicator_id,batch_id)
    assessment_score = self.assessment_scores.find(:first, :conditions => { :student_id => self.id,:descriptive_indicator_id=>indicator_id,:batch_id=>batch_id })
    assessment_score.nil? ? assessment_scores.build(:descriptive_indicator_id=>indicator_id,:batch_id=>batch_id) : assessment_score
  end

  def has_higher_priority_ranking_level(ranking_level_id,type,subject_id)
    ranking_level = RankingLevel.find(ranking_level_id)
    higher_levels = RankingLevel.find(:all,:conditions=>["course_id = ? AND priority < ?", ranking_level.course_id,ranking_level.priority])
    if higher_levels.empty?
      return false
    else
      higher_levels.each do|level|
        if type=="subject"
          score = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(self.id,subject_id,self.batch_id,"s")
          unless score.nil?
            if self.batch.gpa_enabled?
              return true if((score.marks < level.gpa if level.marks_limit_type=="upper") or (score.marks >= level.gpa if level.marks_limit_type=="lower") or (score.marks == level.gpa if level.marks_limit_type=="exact"))
            else
              return true if((score.marks < level.marks if level.marks_limit_type=="upper") or (score.marks >= level.marks if level.marks_limit_type=="lower") or (score.marks == level.marks if level.marks_limit_type=="exact"))
            end
          end
        elsif type=="overall"
          unless level.subject_count.nil?
            unless level.full_course==true
              subjects = self.batch.subjects
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:batch_id=>self.batch.id,:subject_id=>subjects.collect(&:id),:score_type=>"s"})
            else
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:score_type=>"s"})
            end
            unless scores.empty?
              if self.batch.gpa_enabled?
                scores.reject!{|s| !((s.marks < level.gpa if level.marks_limit_type=="upper") or (s.marks >= level.gpa if level.marks_limit_type=="lower") or (s.marks == level.gpa if level.marks_limit_type=="exact"))}
              else
                scores.reject!{|s| !((s.marks < level.marks if level.marks_limit_type=="upper") or (s.marks >= level.marks if level.marks_limit_type=="lower") or (s.marks == level.marks if level.marks_limit_type=="exact"))}
              end
              unless scores.empty?
                sub_count = level.subject_count
                if level.subject_limit_type=="upper"
                  return true if scores.count < sub_count
                elsif level.subject_limit_type=="exact"
                  return true if scores.count == sub_count
                else
                  return true if scores.count >= sub_count
                end
              end
            end
          else
            unless level.full_course==true
              score = GroupedExamReport.find_by_student_id(self.id,:conditions=>{:batch_id=>self.batch.id,:score_type=>"c"})
            else
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(self.id,"c")
              unless marks.empty?
                marks.map{|m| total_student_score+=m.marks}
                avg_student_score = total_student_score.to_f/marks.count.to_f
                marks.first.marks = avg_student_score
                score = marks.first
              end
            end
            unless score.nil?
              if self.batch.gpa_enabled?
                return true if((score.marks < level.gpa if level.marks_limit_type=="upper") or (score.marks >= level.gpa if level.marks_limit_type=="lower") or (score.marks == level.gpa if level.marks_limit_type=="exact"))
              else
                return true if((score.marks < level.marks if level.marks_limit_type=="upper") or (score.marks >= level.marks if level.marks_limit_type=="lower") or (score.marks == level.marks if level.marks_limit_type=="exact"))
              end
            end
          end
        elsif type=="course"
          unless level.subject_count.nil?
            scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:score_type=>"s"})
            unless scores.empty?
              if level.marks_limit_type=="upper"
                scores.reject!{|s| !(((s.marks < level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < level.marks unless level.marks.nil?))}
              elsif level.marks_limit_type=="exact"
                scores.reject!{|s| !(((s.marks == level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == level.marks unless level.marks.nil?))}
              else
                scores.reject!{|s| !(((s.marks >= level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= level.marks unless level.marks.nil?))}
              end
              unless scores.empty?
                sub_count = level.subject_count
                unless level.full_course==true
                  batch_ids = scores.collect(&:batch_id)
                  batch_ids.each do|batch_id|
                    unless batch_ids.empty?
                      count = batch_ids.count(batch_id)
                      if level.subject_limit_type=="upper"
                        return true if count < sub_count
                      elsif level.subject_limit_type=="exact"
                        return true if count == sub_count
                      else
                        return true if count >= sub_count
                      end
                      batch_ids.delete(batch_id)
                    end
                  end
                else
                  if level.subject_limit_type=="upper"
                    return true if scores.count < sub_count
                  elsif level.subject_limit_type=="exact"
                    return true if scores.count == sub_count
                  else
                    return true if scores.count >= sub_count
                  end
                end
              end
            end
          else
            unless level.full_course==true
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:score_type=>"c"})
              unless scores.empty?
                if level.marks_limit_type=="upper"
                  scores.reject!{|s| !(((s.marks < level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < level.marks unless level.marks.nil?))}
                elsif level.marks_limit_type=="exact"
                  scores.reject!{|s| !(((s.marks == level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == level.marks unless level.marks.nil?))}
                else
                  scores.reject!{|s| !(((s.marks >= level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= level.marks unless level.marks.nil?))}
                end
                return true unless scores.empty?
              end
            else
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(self.id,"c")
              unless marks.empty?
                marks.map{|m| total_student_score+=m.marks}
                avg_student_score = total_student_score.to_f/marks.count.to_f
                if level.marks_limit_type=="upper"
                  return true if(((avg_student_score < level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score < level.marks unless level.marks.nil?))
                elsif level.marks_limit_type=="exact"
                  return true if(((avg_student_score == level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score == level.marks unless level.marks.nil?))
                else
                  return true if(((avg_student_score >= level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score >= level.marks unless level.marks.nil?))
                end
              end
            end
          end
        end
      end
    end
    return false
  end


end
