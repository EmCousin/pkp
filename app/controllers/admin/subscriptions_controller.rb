class Admin::SubscriptionsController < AdminController
  def index
    @subscriptions = Subscription.all
  end

  def show
    @subscription = Subscription.find(params[:id])
  end

  def new
    @subscription = Subscription.new
  end

  def create
    @subscription = Subscription.new(subscription_params)
    @subscription.year = Time.now.year
    @subscription.fee = 0
    if @subscription.save
      @subscription.fee = @subscription.compute_fee
      @subscription.save
      redirect_to admin_subscriptions_path, notice: 'Inscription créée avec succès !'
    else
      render :new
    end
  end

  def edit
    @subscription = Subscription.find(params[:id])
  end

  def update
    @subscription = Subscription.find(params[:id])
    if @subscription.update(subscription_params)
      @subscription.fee = @subscription.compute_fee
      @subscription.save
      redirect_to admin_subscriptions_path, notice: 'Inscription modifiée avec succès !'
    else
      render :edit
    end
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy
    redirect_to admin_subscriptions_path, notice: 'Inscription supprimée avec succès !'
  end

  def unlink_course
    @subscription = Subscription.find(params[:id])
    @course = @subscription.courses.find(params[:course_id])
    @subscription.course_ids -= [@course.id]
    redirect_back fallback_location: root_path, notice: 'Cours retiré avec succès !'
  end

  private

  def subscription_params
    params.require(:subscription).permit(:member_id, course_ids: [])
  end
end
