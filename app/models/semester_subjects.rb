class SemesterSubjects < ActiveRecord::Base
	belongs_to :san_subject, :foreign_key=>:subject_id
	belongs_to :san_semester, :foreign_key=>:semester_id
end
