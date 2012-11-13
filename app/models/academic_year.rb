class AcademicYear < ActiveRecord::Base
  has_many :san_semesters

  validates_uniqueness_of :start_date

  def name
    return "#{self.start_date.year}-#{self.end_date.year}"
  end

  def previous
    sorted = AcademicYear.all.sort{|a, b| a.start_date<=>b.start_date}
    ind = sorted.index{|a| a.id == self.id}
    previous_ind = ind - 1
    if previous_ind==-1
      return nil
    else 
      return sorted[previous_ind]
    end
  end

  def next
    sorted = AcademicYear.all.sort{|a, b| a.start_date<=>b.start_date}
    ind = sorted.index{|a| a.id == self.id}
    next_ind = ind + 1
    if next_ind==sorted.length
      return nil
    else 
      return sorted[next_ind]
    end
  end

  def n_subscribed_students
    students = StudentsSubject.find_all_by_academic_year_id(self.id).map(&:student_id).uniq
    return students.length
  end
end
