class SemesterSubjects < ActiveRecord::Base
	belongs_to :san_subject
	belongs_to :san_semester
end
