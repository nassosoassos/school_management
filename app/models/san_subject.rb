class SanSubject < ActiveRecord::Base
  has_many :student, :through => :students_subject
end
