# frozen_string_literal: true

class CreateSubscriptionForm
  include ActiveModel::Model

  validates_presence_of :user, :course_ids, :category

  attr_accessor :user, :course_ids, :category
  attr_reader :subscription

  def courses
    @courses ||= category.present? ? Course.available(Time.now.year).where(category: category).order(:created_at) : Course.none
  end

  def submit
    return false unless valid?

    subscription = user.subscriptions.new(subscription_attributes)
    @subscription = CreateSubscriptionService.new(subscription).perform!

    return true if @subscription.valid?

    errors.merge!(@subscription.errors)

    false
  end

  private

  def subscription_attributes
    {
      course_ids: course_ids
    }
  end
end
