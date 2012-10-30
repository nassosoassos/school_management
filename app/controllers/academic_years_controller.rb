class AcademicYearsController < ApplicationController
  filter_access_to :all
  before_filter :login_required

  def index 
    @academic_years = AcademicYear.paginate :page=>params[:page], :per_page=>15
  end

   # GET /academic_year/new
  # GET /san_subjects/new.xml
  def new
    @academic_year = AcademicYear.new

    respond_to do |format|
      #format.html # new.html.erb
      #format.xml  { render :xml => @san_subject }
      format.js { render :action => 'new' }
    end
  end

  # GET /san_subjects/1/edit
  def edit
    @academic_year = AcademicYear.find(params[:id])
    respond_to do |format|
      format.html { }
      format.js {render :action => 'edit' }
    end
  end

  # POST /san_subjects
  # POST /san_subjects.xml
  def create
    @academic_year = AcademicYear.new(params[:academic_year])

    if @academic_year.save
      @academic_years = AcademicYear.paginate :page=>params[:page], :per_page=>15

      flash[:notice] = t('flash_msg48')
    else
      @error = true
    end
  end

  # PUT /san_subjects/1
  # PUT /san_subjects/1.xml
  def update
    @academic_year = AcademicYear.find(params[:id])

    if @academic_year.update_attributes(params[:san_subject])
      @academic_years = AcademicYear.paginate :page=>params[:page], :per_page=>15
      flash[:notice] = t('flash_msg45')
    else
      @errors = @academic_year.errors
    end
  end

  # DELETE /san_subjects/1
  # DELETE /san_subjects/1.xml
  def destroy
    @academic_year = AcademicYear.find(params[:id])
    @academic_year.destroy

    respond_to do |format|
      format.html { redirect_to(academics_subjects_url) }
      format.xml  { head :ok }
    end
  end
 
end
