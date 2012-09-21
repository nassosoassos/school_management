class SanSemester < ActiveRecord::Base
  belongs_to :group
  has_many :active_subjects, :through => :semester_subjects, :source => :subject_id
end
