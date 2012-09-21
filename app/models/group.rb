class Group < ActiveRecord::Base
	has_many :san_semesters
	has_many :students
end
