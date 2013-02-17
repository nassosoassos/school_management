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
      if (previous_year and g_ac_year.id==previous_year.id) or (pprevious_year and g_ac_year.id==pprevious_year.id)
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
