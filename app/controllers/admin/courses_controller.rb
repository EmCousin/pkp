class Admin::CoursesController < AdminController
  def index
    @courses = Course.all
  end

  def show
    @course = Course.find(params[:id])
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.create(course_params)
  end

  def edit
    @course = Course.find_by(id: params[:id])
  end

  def update
    @course = Course.find_by(id: params[:id])
  end

  def destroy
    @course = Course.find_by(id: params[:id])
    @course.destroy
  end
end
