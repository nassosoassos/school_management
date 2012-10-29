class SanSubjectsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  # GET /san_subjects
  # GET /san_subjects.xml
  def index
    @san_university_subjects = SanSubject.paginate :page=>params[:page], :per_page=>15, :conditions=>{:kind=>'University'}
    @san_military_subjects = SanSubject.paginate :page=>params[:page], :per_page=>15, :conditions=>{:kind=>'Military'}

#    respond_to do |format|
#      format.html # index.html.erb
#      format.xml  { render :xml => @san_subjects }
#    end
  end

  # GET /san_subjects/1
  # GET /san_subjects/1.xml
  def show
    @san_subject = SanSubject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @san_subject }
    end
  end

  # GET /san_subjects/new
  # GET /san_subjects/new.xml
  def new
    @san_subject = SanSubject.new

    respond_to do |format|
      #format.html # new.html.erb
      #format.xml  { render :xml => @san_subject }
      format.js { render :action => 'new' }
    end
  end

  # GET /san_subjects/1/edit
  def edit
    @san_subject = SanSubject.find(params[:id])
    respond_to do |format|
      format.html { }
      format.js {render :action => 'edit' }
    end
  end

  # POST /san_subjects
  # POST /san_subjects.xml
  def create
    @san_subject = SanSubject.new(params[:san_subject])

    if @san_subject.save

      @san_university_subjects = SanSubject.paginate :page=>params[:page], :per_page=>15, :conditions=>{:kind=>'University'}
      @san_military_subjects = SanSubject.paginate :page=>params[:page], :per_page=>15, :conditions=>{:kind=>'Military'}
      flash[:notice] = t('flash_msg44')
    else
      @error = true
    end
  end

  # PUT /san_subjects/1
  # PUT /san_subjects/1.xml
  def update
    @san_subject = SanSubject.find(params[:id])

    if @san_subject.update_attributes(params[:san_subject])
      @san_university_subjects = SanSubject.paginate :page=>params[:page], :per_page=>15, :conditions=>{:kind=>'University'}
      @san_military_subjects = SanSubject.paginate :page=>params[:page], :per_page=>15, :conditions=>{:kind=>'Military'}
      flash[:notice] = t('flash_msg45')
    else
      @errors = @san_subject.errors
    end
  end

  # DELETE /san_subjects/1
  # DELETE /san_subjects/1.xml
  def destroy
    @san_subject = SanSubject.find(params[:id])
    @san_subject.destroy

    respond_to do |format|
      format.html { redirect_to(san_subjects_url) }
      format.xml  { head :ok }
    end
  end
end
