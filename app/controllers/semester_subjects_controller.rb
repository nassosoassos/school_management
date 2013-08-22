class SemesterSubjectsController < ApplicationController
  # GET /semester_subjects
  # GET /semester_subjects.xml
  def index
    @semester_subjects = SemesterSubject.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @semester_subjects }
    end
  end

  # GET /semester_subjects/1
  # GET /semester_subjects/1.xml
  def show
    @semester_subject = SemesterSubject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @semester_subject }
    end
  end

  # GET /semester_subjects/new
  # GET /semester_subjects/new.xml
  def new
    @semester_subject = SemesterSubject.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @semester_subject }
    end
  end

  # GET /semester_subjects/1/edit
  def edit
    @semester_subject = SemesterSubject.find(params[:id])
  end

  # POST /semester_subjects
  # POST /semester_subjects.xml
  def create
    @semester_subject = SemesterSubject.new(params[:san_semester])

    respond_to do |format|
      if @semester_subject.save
        flash[:notice] = 'SemesterSubject was successfully created.'
        format.html { redirect_to(@san_semester) }
        format.xml  { render :xml => @san_semester, :status => :created, :location => @san_semester }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @san_semester.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /semester_subjects/1
  # PUT /semester_subjects/1.xml
  def update
    @semester_subject = SemesterSubject.find(params[:id])

    respond_to do |format|
      if @semester_subject.update_attributes(params[:semester_subject])
        flash[:notice] = 'SemesterSubject was successfully updated.'
        format.html { redirect_to(@semester_subject) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @semester_subject.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /semester_subjects/1
  # DELETE /semester_subjects/1.xml
  def destroy
    @semester_subject = SemesterSubject.find(params[:id])
    @semester_subject.destroy

    respond_to do |format|
      format.html { redirect_to(semester_subjects_url) }
      format.xml  { head :ok }
    end
  end
end
