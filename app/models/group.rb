class Group < ActiveRecord::Base
	has_many :san_semesters
	has_many :students
    has_many :students_subjects

    def get_hierarchy_list_for_year(year)
      students = Student.find_all_by_group_id(self.id)
      unsorted_students = Array.new
      undef_students = Array.new
      students.each do |stu|
        total_gpa, total_sum, uni_gpa, mil_gpa, mil_p_gpa, n_unfinished_subjects = stu.gpa_for_year(year, 'all')      
        stu_info = {:gpa=>total_gpa, :total_sum=>total_sum, :uni_gpa=>uni_gpa, :full_name=>stu.full_name,
          :mil_gpa=>mil_gpa,:mil_p_gpa=>mil_p_gpa, :n_unfinished_subjects=>n_unfinished_subjects, 
          :father=>stu.fathers_first_name, :gender=>stu.gender, :id=>stu.id}
        if total_gpa!=nil and uni_gpa!=nil
          unsorted_students.push(stu_info)
        else
          undef_students.push(stu_info)
        end
      end

      # Sort by unfinished subjects and then gpa and then uni_gpa
      sorted_students = unsorted_students.sort {|a,b| a[:n_unfinished_subjects]==b[:n_unfinished_subjects]? (b[:gpa] == a[:gpa]? b[:uni_gpa] <=> a[:uni_gpa] : b[:gpa] <=> a[:gpa]) : a[:n_unfinished_subjects] <=> b[:n_unfinished_subjects]}

      if undef_students.length>0
        undef_students.sort! {|a,b| a[:full_name] <=> b[:full_name]}
      end

      return sorted_students, undef_students
    end
end
