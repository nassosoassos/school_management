class AcademicYear < ActiveRecord::Base
  has_many :san_semesters

  validates_uniqueness_of :start_date

  def name
    return "#{self.start_date.year}-#{self.end_date.year}"
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
end
