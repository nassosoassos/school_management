class StudentLanguage < ActiveRecord::Base
  belongs_to :student
  belongs_to :foreign_language
end
