class SanSemestersController < ApplicationController
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

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @san_semester }
    end
  end

  # GET /san_semesters/1/edit
  def edit
    @san_semester = SanSemester.find(params[:id])
  end

  # POST /san_semesters
  # POST /san_semesters.xml
  def create
    @san_semester = SanSemester.new(params[:san_semester])

    respond_to do |format|
      if @san_semester.save
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
