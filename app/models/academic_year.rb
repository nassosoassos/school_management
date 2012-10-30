class AcademicYear < ActiveRecord::Base
  has_many :san_semesters

  validates_uniqueness_of :start_date

  def name
    return "#{self.start_date.year}-#{self.end_date.year}"
  end
end
