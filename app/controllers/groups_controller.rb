class GroupsController < ApplicationController
  filter_access_to :all
  before_filter :login_required

  def debug
      @group = Group.find(params[:id])
      @student_subjects_grades = StudentsSubject.find_all_by_subject_id_and_group_id("4", "2")
      
  end
  def show_lists
    group = Group.find(params[:id])
    type = Integer(params[:list_type])
    year = params[:group_year]
    if year == 'all'
      year = SanSemester.find_all_by_group_id(group.id).map(&:year).uniq
    end
    @sorted_students, @undef_students = group.get_hierarchy_list_for_year(year)
    render(:update) do |page|
        page.replace_html 'list', :partial=>'hierarchy_list'
    end
  end
  def lists
    @group = Group.find(params[:id])
    @all_years = SanSemester.find_all_by_group_id(@group.id).map(&:year).uniq
  end

  def print_lists
    group = Group.find(params[:id])
    type = Integer(params[:list_type])
    @year = params[:group_year]
    if @year == 'all'
      @year = SanSemester.find_all_by_group_id(group.id).map(&:year).uniq
    end
    @sorted_students, @undef_students = group.get_hierarchy_list_for_year(@year)
    if type ==0
      render :pdf=>'hierarchy_list', :template=>'groups/hierarchy_list_pdf.erb', :orientation=>'Landscape' 
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
    semester.update_attributes({:group_id=>@group.id}) 
    @group.update_attributes({:active_semester_id=>semester.id})

    # Subscribe all group students to the semester subjects
    group_students = Student.find_all_by_group_id(@group.id)
    semester_subjects = SemesterSubjects.find_all_by_semester_id_and_optional(semester.id,false)

    group_students.each do |student|
      student_performance = StudentMilitaryPerformance.find_or_create_by_student_id_and_san_semester_id(student.id, semester.id)
	  semester_subjects.each do |subject|
	   student_subject = StudentsSubject.find_or_create_by_student_id_and_subject_id(student.id, subject.subject_id)
       student_subject.update_attributes({:group_id=>@group.id, :san_semester_id=>semester.id})
	  end
    end

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
    semester.update_attributes({:group_id=>nil}) 
    if @group.active_semester_id == semester.id
      @group.update_attributes({:active_semester_id=>nil})
    end

    # Unsubscribe all group students from the semester subjects
    group_students = Student.find_all_by_group_id(@group.id)
    semester_subjects = SemesterSubjects.find_all_by_semester_id_and_optional(semester.id,false)

    group_students.each do |student|
      student_performance = StudentMilitaryPerformance.delete(:student_id=>student.id, :san_semester_id=>semester.id)
      StudentsSubject.delete_all(:student_id=>student.id, :san_semester_id=>semester.id)
    end

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
    group_students = Student.find_all_by_group_id(@group.id)
    @students = group_students.sort!{|a, b| a.last_name<=> b.last_name}.paginate :page=>params[:page], :per_page=>15
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
