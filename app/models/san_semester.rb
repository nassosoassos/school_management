class SanSemester < ActiveRecord::Base
  belongs_to :group
  belongs_to :academic_year
  has_many :san_subjects, :through => :semester_subjects, :source => :subject_id
  has_many :semester_subjects, :foreign_key => :semester_id, :dependent => :destroy
  validates_presence_of :number, :academic_year_id, :uni_weight, :mil_weight, :mil_p_weight
  validates_uniqueness_of :number, :scope=>[:academic_year_id], :message => "#{t('must_be_unique_for_academic_year')}"

  # uni_weight: The weighting coefficient for the university GPA
  validates_numericality_of :uni_weight, :only_integer=>true, :greater_than=>1, :less_than=>100, :allow_nil=>true, 
    :message => "#{t('must_be_greater_than_zero')}"
  validates_numericality_of :mil_weight, :greater_than=>0, :allow_nil=>true, 
    :message => "#{t('must_be_greater_than_zero')}"
  validates_numericality_of :mil_p_weight, :greater_than=>0, :allow_nil=>true, 
    :message => "#{t('must_be_greater_than_zero')}"


  def update_subjects(subject_ids, optional)
      # Adding or removing subjects from the semester. It's supposed
      # to run twice, once for the 'compulsory' and once for the 'optional'
      # subjects.
      #   subject_ids : list of subject IDs
      #   optional    : boolean
      #
      # Update:
      #   - If a group is subscribed to a semester, its students' student_subjects 
      #     are updated accordingly (13/12/12)
      current_subjects = SemesterSubjects.find_all_by_semester_id_and_optional(self.id, optional).map(&:subject_id)
      if current_subjects.blank?
        current_subjects = []
      end
      subjects_to_add = []
      subjects_to_remove = current_subjects
      if subject_ids != nil 
        # Set difference to find the subjects to add. Nice that ruby implements this.
        subjects_to_add = subject_ids - current_subjects

        # Set difference to find the subjects to remove.
        subjects_to_remove = current_subjects - subject_ids
      end
      subjects_to_add.each do |c|
          SemesterSubjects.create({ :semester_id => self.id, :subject_id => c, :optional => optional})
      end
      subjects_to_remove.each do |c|
          SemesterSubjects.find_by_semester_id_and_subject_id_and_optional( self.id, c, optional).destroy
      end
      unless (subjects_to_add.empty? or self.group.nil?)
        self.group.subscribe_to_semester_subjects(subjects_to_add)
      end
      if (subjects_to_add.length>0 or subjects_to_remove.length>0) and self.group
        self.group.reset_seniority(san_semester.academic_year)
        self.group.estimate_seniority_batch(san_semester.academic_year)
      end
  end
end
