class SanSubject < ActiveRecord::Base
  has_many :student, :through => :students_subject
  has_many :students_subjects, :foreign_key => :subject_id, :dependent => :destroy
  has_many :semester_subjects, :class_name=>"SemesterSubjects", :foreign_key => :subject_id, :dependent => :destroy
  validates_presence_of :title, :kind
  validates_uniqueness_of :title, :case_sensitive => false
end
