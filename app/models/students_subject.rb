#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class StudentsSubject < ActiveRecord::Base
  belongs_to :student
  belongs_to :subject
  belongs_to :san_subject, :foreign_key => :subject_id
  belongs_to :san_semester
  belongs_to :academic_year
  belongs_to :semester_subjects 

  def student_assigned(student,subject)
    StudentsSubject.find_by_student_id_and_subject_id(student,subject)
  end
end
