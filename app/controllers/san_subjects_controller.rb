class SanSubjectsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  # GET /san_subjects
  # GET /san_subjects.xml
  def index
    @san_subjects = SanSubject.all

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
      format.html # new.html.erb
      format.xml  { render :xml => @san_subject }
    end
  end

  # GET /san_subjects/1/edit
  def edit
    @san_subject = SanSubject.find(params[:id])
  end

  # POST /san_subjects
  # POST /san_subjects.xml
  def create
    @san_subject = SanSubject.new(params[:san_subject])

    respond_to do |format|
      if @san_subject.save
        flash[:notice] = 'SanSubject was successfully created.'
        format.html { redirect_to(@san_subject) }
        format.xml  { render :xml => @san_subject, :status => :created, :location => @san_subject }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @san_subject.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /san_subjects/1
  # PUT /san_subjects/1.xml
  def update
    @san_subject = SanSubject.find(params[:id])

    respond_to do |format|
      if @san_subject.update_attributes(params[:san_subject])
        flash[:notice] = 'SanSubject was successfully updated.'
        format.html { redirect_to(@san_subject) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @san_subject.errors, :status => :unprocessable_entity }
      end
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
