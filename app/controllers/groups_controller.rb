class GroupsController < ApplicationController
  filter_access_to :all
  before_filter :login_required

  def debug
      @group = Group.find(params[:id])
      @student_subjects_grades = StudentsSubject.find_all_by_subject_id_and_group_id("4", "2")
      
  end
  def show_lists
    group = Group.find(params[:id])
    @type = Integer(params[:list_type])
    @exam_period = params[:exam_period]
    year_id = params[:group_year]
    year = AcademicYear.find(year_id)
    if @type != 3
      if @exam_period=='all'
        @successful_students, @successful_september_students, @unsuccessful_students, @undef_students = group.get_seniority_list_for_year(year, 'c')
      else
        @successful_students, @successful_september_students, @unsuccessful_students, @undef_students = group.get_seniority_list_for_year(year, @exam_period)
      end
      if @type==0
        if @exam_period=='c'
          @all_students = @successful_september_students + @unsuccessful_students
        elsif @exam_period=='b'
          @all_students = @successful_students + @unsuccessful_students
        else
          @all_students = @successful_students + @successful_september_students + @unsuccessful_students
        end
      elsif @type==1
        if @exam_period=='b'
          @all_students = @successful_students
        elsif @exam_period=='c'
          @all_students = @successful_september_students
        else
          @all_students = @successful_students + @successful_september_students
        end
      elsif @type==2
        @all_students = @unsuccessful_students
      end
    else
      @successful_students, @undef_students = group.get_overall_seniority_list
      @all_students = @successful_students
    end
    index = 0
    @all_students.each do |stu|
      index += 1
      stu[:index] = index
    end

    render(:update) do |page|
        page.replace_html 'list', :partial=>'hierarchy_list'
    end
  end
  def lists
    @group = Group.find(params[:id])
    @all_years = SanSemester.find_all_by_group_id(@group.id).map{|a| a.academic_year}.uniq
  end

  def print_lists
    @group = Group.find(params[:id])
    @type = Integer(params[:list_type])
    @exam_period = params[:exam_period]
    year_id = params[:group_year]
    @year = AcademicYear.find(year_id)
    @group_year_number = @group.find_year_number(@year).to_s
    if @type != 3
      if @exam_period=='all'
        @successful_students, @successful_september_students, @unsuccessful_students, @undef_students = @group.get_seniority_list_for_year(@year, 'c')
      else
        @successful_students, @successful_september_students, @unsuccessful_students, @undef_students = @group.get_seniority_list_for_year(@year, @exam_period)
      end
      if @type==0
        @layout = 'Portrait'
        @students_per_page = 55
        @show_all_grades = false
        @show_final_grade = false
        @show_notes = false
        @list_title = 'Λίστα Αρχαιότητας Σπουδαστών'
        if @exam_period=='c'
          @all_students = @successful_september_students + @unsuccessful_students
        elsif @exam_period=='b'
          @all_students = @successful_students + @unsuccessful_students
        else
          @all_students = @successful_students + @successful_september_students + @unsuccessful_students
        end
      elsif @type==1
        @list_title = 'Πίνακας Περατωσάντων Σπουδαστών'
        @show_notes = true
        @layout = 'Landscape'
        @show_all_grades = true
        @show_final_grade = false
        @students_per_page = 20
        if @exam_period=='b'
          @all_students = @successful_students
        elsif @exam_period=='c'
          @all_students = @successful_september_students
        else
          @all_students = @successful_students + @successful_september_students
        end
      elsif @type==2
        @list_title = 'Πίνακας Μη Περατωσάντων Σπουδαστών'
        @show_all_grades = false
        @show_final_grade = false
        @show_notes = true
        @layout = 'Landscape'
        @students_per_page = 20
        @all_students = @unsuccessful_students
      end
    else
      @layout = 'Portrait'
      @show_notes = true
      @list_title = 'Πίνακας Αποφοιτώντων Σπουδαστών'
      @show_all_grades = false
      @show_final_grade = false
      @successful_students, @undef_students = @group.get_overall_seniority_list
      @all_students = @successful_students
    end
    index = 0
    @all_students.each do |stu|
      index += 1
      stu[:index] = index
    end

    directors_full_name = Configuration.find_by_config_key('DirectorsFullName').config_value
    directors_rank = Configuration.find_by_config_key('DirectorsRank').config_value
    directors_arms = Configuration.find_by_config_key('DirectorsArms').config_value

    edu_directors_full_name = Configuration.find_by_config_key('EduDirectorsFullName').config_value
    edu_directors_rank = Configuration.find_by_config_key('EduDirectorsRank').config_value
    edu_directors_arms = Configuration.find_by_config_key('EduDirectorsArms').config_value
  
    directors_full_name_last_char = directors_full_name.split('').last
   if directors_full_name_last_char=='Σ' or directors_full_name_last_char=='ς' 
     @directors_gender = 'm'
   else
     @directors_gender = 'f'
   end
   @directors_full_rank_and_name = "%s (%s) %s" % [directors_rank, directors_arms, directors_full_name]

    edu_directors_full_name_last_char = edu_directors_full_name.split('').last
   if edu_directors_full_name_last_char=='Σ' or edu_directors_full_name_last_char=='ς' 
     @edu_directors_gender = 'm'
   else
     @edu_directors_gender = 'f'
   end
   @edu_directors_full_rank_and_name = "%s (%s) %s" % [edu_directors_rank, edu_directors_arms, edu_directors_full_name]
   respond_to do |format|
     if params[:commit]=='Εκτύπωση (pdf)'
       format.pdf do
         render :pdf=>'hierarchy_list', :template=>'groups/hierarchy_list_pdf.erb', :orientation=>@layout
       end
     elsif params[:commit]=='Εξαγωγή (xls)'
       format.xls {
         require 'spreadsheet'
         students = Spreadsheet::Workbook.new
         list = students.create_worksheet :name=>@list_title
         list.row(0).concat %w{Α/Α ΑΜ Ονοματεπώνυμο Πατρώνυμο Πανεπ. Σχολή Προσόντα Μόρια Βαθμός Μεταφερόμενα}
         @all_students.each_with_index { |student, i|
           list.row(i+1).push student[:index],student[:admission_no],student[:full_name],student[:father], student[:uni_gpa], student[:mil_gpa], student[:mil_p_gpa], student[:total_sum], student[:gpa], student[:n_unfinished_subjects]
         }
         header_format = Spreadsheet::Format.new :color=>:green, :weight=>:bold
         list.row(0).default_format = header_format
         #output to blob object
         blob = StringIO.new('')
         students.write blob
         #respond with blob object as a file
        send_data blob.string, :type=>:xls, :filename=>'list.xls'
       }
     end
   end
  end

  def grades
      @group_semesters = SanSemester.find_all_by_group_id(params[:id])
  end

  def update_grades 
    @student_subjects_grades = StudentsSubject.find_all_by_subject_id_and_group_id(params[:students_subjects][:subject_id], params[:id])
    @group=Group.find(params[:id])
    @student_subjects_grades.each do |grade_set|
      student_id = grade_set.student_id
      a_grade = params[:students_subjects][:a_grade][student_id.to_s]
      b_grade = params[:students_subjects][:b_grade][student_id.to_s]
      c_grade = params[:students_subjects][:c_grade][student_id.to_s]
      grade_set.update_attributes({:a_grade=>a_grade, :b_grade=>b_grade, :c_grade=>c_grade})
    end
    render(:update) do |page|
    	flash[:notice] = 'Η ενημέρωση των βαθμών πραγματοποιήθηκε επιτυχώς.'
        page.replace_html 'grades', :partial=> 'grades'
    end
  end

  def edit_semesters
    @group = Group.find(params[:id])
    semesters= SanSemester.find_all_by_group_id(params[:id])
    @active_semesters = Array.new
    semesters.each do |sem|
      is_active = false
      if sem.id == @group.active_semester_id
        is_active = true
      end
      sem_info = {:number=>sem.number, :year=>sem.academic_year.name, :id=>sem.id, :is_active=>is_active }
      @active_semesters.push(sem_info)
    end
    if request.post? 
      semesters.sort!{|a,b| b.number<=>a.number}.each do |sem|
        if params[:group][sem.id.to_s]=='past'
          if @group.active_semester_id==sem.id
            @group.update_attributes({:active_semester_id=>nil})
          end
        else
            @group.update_attributes({:active_semester_id=>sem.id})
        end
      end
      if params[:group][:graduated]=='1'
        @group.graduate(params[:graduation_date])
      else
        @group.revert_graduation()
      end
      flash[:notice] = "Τα στοιχεία της τάξης ενημερώθηκαν."
    end
  end

  # GET /groups/1/list_grades
  def list_grades
      @student_subjects_grades = StudentsSubject.find_all_by_subject_id_and_group_id(params[:subject_id], params[:id])
      @group=Group.find(params[:id])
      render(:update) do |page|
        page.replace_html 'grades', :partial=> 'grades'
      end
  end

  # GET /groups/1/select_subject
  def select_subject
      @semester_subjects_relations = SemesterSubjects.find_all_by_semester_id(params[:semester_id])
      @group_semester_subjects = SanSubject.find(@semester_subjects_relations.map(&:subject_id).uniq)
      #@student_subjects_grades = Array.new
      #@group=Group.find(params[:id])
      render(:update) do |page|
        page.replace_html 'subject_selection', :partial=> 'subject_selection'
      #  page.replace_html 'grades', :partial=> 'grades'
      end
  end

  # POST /groups/1/subscribe_to_semester
  def subscribe_to_semester
    group_id = params[:id]
    @group = Group.find(group_id)
    @san_semester = SanSemester.find(:first, :conditions=> {:year=>params[:san_semester][:year], :number=>params[:san_semester][:number]})
    @san_semester.update_attributes({:group_id=>group_id}) 

    # Subscribe all group students to the semester subjects
    group_students = Student.find_all_by_group_id(group_id)
    semester_subjects = SemesterSubjects.find_all_by_semester_id_and_optional(@san_semester.id,false)
    

    group_students.each do |student|
      student_performance = StudentMilitaryPerformance.find_or_create_by_student_id_and_san_semester_id(student.id, @san_semester.id)
	  semester_subjects.each do |subject|
	   student_subject = StudentsSubject.find_or_create_by_student_id_and_subject_id(student.id, subject.subject_id)
       student_subject.update_attributes({:group_id=>group_id, :san_semester_id=>@san_semester.id})
	  end
    end

    respond_to do |format|
	flash[:notice] = 'Η εγγραφή σε εξάμηνο πραγματοποιήθηκε επιτυχώς.'
	format.html { redirect_to(@group) }
	format.xml  { head :ok }
    end
  end

  # GET /show_group_semester
  def show_group_semester 
    @san_semester = SanSemester.find(:first, :conditions => {:year => params[:semester_year], :number => params[:semester_number]})
    @semester_year = params[:semester_year]
    @semester_number = params[:semester_number]
    render(:update) do |page|
      page.replace_html 'san_semester', :partial=> 'semester'
      page.replace_html 'subscription', :partial=> 'subscribe'
    end
  end

  def add_semester
    @group = Group.find(params[:id])
    semester = SanSemester.find(params[:san_semester][:id])
    @group.subscribe_to_semester(semester)
    flash[:notice] = "Η τάξη εγγράφτηκε στο εξάμηνο κανονικά." 

    semesters= SanSemester.find_all_by_group_id(@group.id)
    @active_semesters = Array.new
    semesters.each do |sem|
      is_active = false
      if sem.id == @group.active_semester_id
        is_active = true
      end
      sem_info = {:number=>sem.number, :year=>sem.year, :id=>sem.id, :is_active=>is_active }
      @active_semesters.push(sem_info)
    end

  end

  def delete_semester
    @group = Group.find(params[:id])
    semester = SanSemester.find(params[:semester_id])

    @group.unsubscribe_from_semester(semester)


    respond_to do |format|
      format.html { redirect_to :action=> "edit_semesters" }
      format.xml  { head :ok }
    end
  end

  def subscribe_semester
    @group = Group.find(params[:id])
    @san_semester = SanSemester.last

    @semester_collection = Array.new
    semesters = SanSemester.find_all_by_group_id(nil)
    semesters.each do |sem|
      sem_info = {:id=>sem.id, :name=>sem.number.to_s + 'ο Εξάμηνο, ' + sem.year}
      @semester_collection.push(sem_info)
    end

    respond_to do |format|
      format.js { render :action => 'semester_subscription' }
    end
  end

  # GET /groups/1/semester_subscription
  def semester_subscription
    @group = Group.find(params[:id])
    @san_semester = SanSemester.last()
    @semester_years = SanSemester.find(:all, :select=>'year').map(&:year).uniq
    @semester_numbers = SanSemester.find(:all, :select=>'number').map(&:number).uniq
  end

  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])
    last_group_year = @group.last_year
    group_smps = StudentMilitaryPerformance.find(:all, :conditions=>{:group_id=>@group.id, :is_active=>true, 
                                                 :academic_year_id=>last_group_year.id},
                                                 :order=>"case when seniority is null then -1 else seniority end asc")
    if group_smps.length < @group.n_students(last_group_year) or  group_smps.select {|a| a.seniority.nil?}.length > 0
      previous_group_year = last_group_year.previous
      if previous_group_year
        group_smps = StudentMilitaryPerformance.find(:all, :conditions=>{:group_id=>@group.id, :is_active=>true,
                                                     :academic_year_id=>previous_group_year.id},
                                                 :order=>"case when seniority is null then -1 else seniority end asc")
        if group_smps.length < @group.n_students(last_group_year) or  group_smps.select {|a| a.seniority.nil?}.length > 0
          all_students = Student.find_all_by_group_id_and_is_active(@group.id, true).sort {|a, b| a.last_name<=>b.last_name}
          @students = all_students.paginate :page=>params[:page], :per_page=>15
        
        else
          @students = group_smps.paginate :page=>params[:page], :per_page=>15
        end
      end
    else
      @students = group_smps.paginate :page=>params[:page], :per_page=>15
    end
    @semesters = SanSemester.find_all_by_group_id(@group.id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new

    respond_to do |format|
      #format.html # new.html.erb
      #format.xml  { render :xml => @group }
      format.js { render :action => 'new' }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
    respond_to do |format|
      format.html { }
      format.js {render :action => 'edit' }
    end
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])

    if @group.save
      flash[:notice] = t('flash_msg46')
      @groups = Group.all
    else
      @error = true
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])

      if @group.update_attributes(params[:group])
        flash[:notice] = t('flash_msg47')
        @groups = Group.all
       # format.html { redirect_to(@group) }
       # format.xml  { head :ok }
      else
       # format.html { render :action => "edit" }
       # format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end
end
