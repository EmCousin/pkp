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
    if @course.save
      redirect_to admin_courses_path, notice: 'Cours créé avec succès !'
    else
      render :new
    end
  end

  def edit
    @course = Course.find(params[:id])
  end

  def update
    @course = Course.find(params[:id])
    if @course.update(course_params)
      redirect_to admin_courses_path, notice: 'Cours modifié avec succès !'
    else
      render :edit
    end
  end

  def destroy
    @course = Course.find(params[:id])
    @course.destroy
    redirect_to admin_courses_path, notice: 'Cours supprimé avec succès !'
  end

  private

  def course_params
    params.require(:course).permit(:title, :description, :capacity, :category)
  end
end
