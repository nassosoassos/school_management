class ClassesController < ApplicationController
  # GET /classes
  # GET /classes.xml
  def index
    @classes = Class.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @classes }
    end
  end

  # GET /classes/1
  # GET /classes/1.xml
  def show
    @class = Class.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @class }
    end
  end

  # GET /classes/new
  # GET /classes/new.xml
  def new
    @class = Class.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @class }
    end
  end

  # GET /classes/1/edit
  def edit
    @class = Class.find(params[:id])
  end

  # POST /classes
  # POST /classes.xml
  def create
    @class = Class.new(params[:class])

    respond_to do |format|
      if @class.save
        flash[:notice] = 'Class was successfully created.'
        format.html { redirect_to(@class) }
        format.xml  { render :xml => @class, :status => :created, :location => @class }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /classes/1
  # PUT /classes/1.xml
  def update
    @class = Class.find(params[:id])

    respond_to do |format|
      if @class.update_attributes(params[:class])
        flash[:notice] = 'Class was successfully updated.'
        format.html { redirect_to(@class) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /classes/1
  # DELETE /classes/1.xml
  def destroy
    @class = Class.find(params[:id])
    @class.destroy

    respond_to do |format|
      format.html { redirect_to(classes_url) }
      format.xml  { head :ok }
    end
  end
end
