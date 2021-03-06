# -*- coding: iso-8859-7 -*-
class SanSemestersController < ApplicationController
  filter_access_to :all
  before_filter :login_required

  
  def add_subjects
    
  end

  # GET /san_semesters
  # GET /san_semesters.xml
  def index
    c_year, p_year = AcademicYear.last_with_semesters
    if p_year.nil?
      @san_semesters = SanSemester.find_all_by_academic_year_id(c_year.id)
    elsif c_year.nil?
      @san_semesters = nil
    else
      @san_semesters = SanSemester.find_all_by_academic_year_id([c_year.id, p_year.id])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @san_semesters }
    end
  end

  def index_all
    @san_semesters = SanSemester.all
    @san_semesters = SanSemester.paginate :page=>params[:page], :per_page=>15, :order=>"academic_year_id DESC"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @san_semesters }
    end
  end

  # GET /san_semesters/1
  # GET /san_semesters/1.xml
  def show
    @san_semester = SanSemester.find(params[:id])
    @semester_subjects = SemesterSubjects.find_all_by_semester_id(@san_semester.id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @san_semester }
    end
  end

  # GET /san_semesters/new
  # GET /san_semesters/new.xml
  def new
    @san_semester = SanSemester.new
    @academic_years = AcademicYear.all

    @uni_subjects = SanSubject.find_all_by_kind("University").sort!{|a,b| a.title<=>b.title}
    @mil_subjects = SanSubject.find_all_by_kind("Military").sort!{|a,b| a.title<=>b.title}

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @san_semester }
    end
  end

  # GET /san_semesters/1/edit
  def edit
    @san_semester = SanSemester.find(params[:id])
    @academic_years = AcademicYear.all
    @uni_subjects = SanSubject.find_all_by_kind("University").sort!{|a,b| a.title<=>b.title}
    @mil_subjects = SanSubject.find_all_by_kind("Military").sort!{|a,b| a.title<=>b.title}
    @compulsory_semester_subjects = SanSubject.find(SemesterSubjects.find_all_by_semester_id_and_optional(@san_semester.id, false).map(&:subject_id))
    @optional_semester_subjects = SanSubject.find(SemesterSubjects.find_all_by_semester_id_and_optional(@san_semester.id, true).map(&:subject_id))
  end

  # POST /san_semesters
  # POST /san_semesters.xml
  def create
    @san_semester = SanSemester.new(params[:san_semester])
    @uni_subjects = SanSubject.find_all_by_kind("University")
    @mil_subjects = SanSubject.find_all_by_kind("Military")
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
          flash[:notice] = 'Το εξάμηνο δημιουργ�?θηκε επιτυχώς.'
          format.html { redirect_to(@san_semester) }
          format.xml  { render :xml => @san_semester, :status => :created, :location => @san_semester }
      else
          flash[:notice] = 'Πρόβλημα στη δημιουργία του εξαμ�?νου.'
          format.html { redirect_to :action => "new" }
          format.xml  { render :xml => @san_semester.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /san_semesters/1
  # PUT /san_semesters/1.xml
  def update
    @san_semester = SanSemester.find(params[:id])

    update_grades = false
    respond_to do |format|
      if @san_semester.group and (@san_semester.uni_weight != params[:san_semester][:uni_weight] or 
        @san_semester.mil_weight != params[:san_semester][:mil_weight] or
        @san_semester.mil_p_weight != params[:san_semester][:mil_p_weight])
        update_grades = true
      end
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
        if update_grades
          @san_semester.group.reset_seniority(@san_semester.academic_year)
          @san_semester.group.estimate_seniority_batch(@san_semester.academic_year)
        end

        flash[:notice] = t('flash_msg43')


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
