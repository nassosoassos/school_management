# -*- coding: iso-8859-7 -*-
class SanSemestersController < ApplicationController
  
  def add_subjects
    
  end

  # GET /san_semesters
  # GET /san_semesters.xml
  def index
    @san_semesters = SanSemester.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @san_semesters }
    end
  end

  # GET /san_semesters/1
  # GET /san_semesters/1.xml
  def show
    @san_semester = SanSemester.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @san_semester }
    end
  end

  # GET /san_semesters/new
  # GET /san_semesters/new.xml
  def new
    @san_semester = SanSemester.new

    @uni_subjects = SanSubject.find_all_by_kind("University")
    @mil_subjects = SanSubject.find_all_by_kind("Military")

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @san_semester }
    end
  end

  # GET /san_semesters/1/edit
  def edit
    @san_semester = SanSemester.find(params[:id])
    @uni_subjects = SanSubject.find_all_by_kind("University")
    @mil_subjects = SanSubject.find_all_by_kind("Military")
    @compulsory_semester_subjects = SanSubject.find(SemesterSubjects.find_all_by_semester_id_and_optional(@san_semester.id, false).map(&:subject_id))
    @optional_semester_subjects = SanSubject.find(SemesterSubjects.find_all_by_semester_id_and_optional(@san_semester.id, true).map(&:subject_id))
  end

  # POST /san_semesters
  # POST /san_semesters.xml
  def create
    @san_semester = SanSemester.new(params[:san_semester])
    created = @san_semester.save

    # Add subjects
    if params[:compulsory_subjects] != nil
      params[:compulsory_subjects].each do |c|
        SemesterSubjects.create({ :semester_id => @san_semester.id, :subject_id => c, :optional => false})
      end
    end

    if params[:optional_subjects] != nil
      params[:optional_subjects].each do |o|
        SemesterSubjects.create({ :semester_id => @san_semester.id, :subject_id => o, :optional => true})
      end
    end

    respond_to do |format|
      if created
        flash[:notice] = 'SanSemester was successfully created.'
        format.html { redirect_to(@san_semester) }
        format.xml  { render :xml => @san_semester, :status => :created, :location => @san_semester }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @san_semester.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /san_semesters/1
  # PUT /san_semesters/1.xml
  def update
    @san_semester = SanSemester.find(params[:id])

    respond_to do |format|
      if @san_semester.update_attributes(params[:san_semester])
        if params[:compulsory_subjects] != nil
          compulsory_subject_ids = params[:compulsory_subjects].map {|s| Integer(s)}
        else
          compulsory_subject_ids = nil
        end
        if params[:optional_subjects] != nil
          optional_subject_ids = params[:optional_subjects].map {|s| Integer(s)}
        else
          optional_subject_ids = nil
        end
        @san_semester.update_subjects(compulsory_subject_ids, false)
        @san_semester.update_subjects(optional_subject_ids, true)

        flash[:notice] = 'SanSemester was successfully updated.'


        format.html { redirect_to(@san_semester) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @san_semester.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /san_semesters/1
  # DELETE /san_semesters/1.xml
  def destroy
    @san_semester = SanSemester.find(params[:id])
    @san_semester.destroy

    respond_to do |format|
      format.html { redirect_to(san_semesters_url) }
      format.xml  { head :ok }
    end
  end
end
