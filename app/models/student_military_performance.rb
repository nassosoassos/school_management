class StudentMilitaryPerformance < ActiveRecord::Base
  belongs_to :student
  belongs_to :group
  belongs_to :academic_year
end
