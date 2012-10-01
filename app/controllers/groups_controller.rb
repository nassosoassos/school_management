class GroupsController < ApplicationController
  def grades
    @group_semesters = SanSemester.find_all_by_group_id(params[:id])
  end

  # GET /groups/1/list_grades
  def list_grades
  end

  # POST /groups/1/subscribe_to_semester
  def subscribe_to_semester
    group_id = params[:id]
    @group = Group.find(group_id)
    @san_semester = SanSemester.find(:first, :conditions=> {:year=>params[:san_semester][:year], :number=>params[:san_semester][:number]})
    @san_semester.update_attributes({:group_id=>group_id}) 

    # Subscribe all group students to the semester subjects
    group_students = Student.find_all_by_group_id(group_id)
    semester_subjects = SemesterSubjects.find_all_by_semester_id(@san_semester.id)

    group_students.each do |student|
	semester_subjects.each do |subject|
	   student_subject = StudentsSubject.find_or_create_by_student_id_and_subject_id(student.id, subject.id)
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

  # GET /groups/1/semester_subscription
  def semester_subscription
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
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
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
