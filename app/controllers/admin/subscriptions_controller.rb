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
    @subscription.fee = 0
    @subscription.year = Time.now.year
    if @subscription.save
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

  private

  def subscription_params
    params.require(:subscription).permit(:member_id, course_ids: [])
  end
end
