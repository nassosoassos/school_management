class SanSemester < ActiveRecord::Base
  belongs_to :group
  has_many :active_subjects, :through => :semester_subjects, :source => :subject_id

  def update_subjects(subject_ids, optional)
      current_subjects = SemesterSubjects.find_all_by_semester_id_and_optional(self.id, optional).map(&:subject_id)
      if current_subjects.blank?
        current_subjects = []
      end
      subjects_to_add = []
      subjects_to_remove = current_subjects
      if subject_ids != nil 
        subjects_to_add = subject_ids - current_subjects
        subjects_to_remove = current_subjects - subject_ids
      end
      subjects_to_add.each do |c|
          SemesterSubjects.create({ :semester_id => self.id, :subject_id => c, :optional => optional})
      end
      subjects_to_remove.each do |c|
          SemesterSubjects.find_by_semester_id_and_subject_id_and_optional( self.id, c, optional).destroy
      end
  end
end
