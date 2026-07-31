# frozen_string_literal: true

class AnnualSubscription < Subscription
  include Subscriptions::Limitable

  attr_accessor :category_id

  delegate :kidz?, :teen?, :adult?, to: :category, prefix: true, allow_nil: true

  validates :member_id, uniqueness: {
                          scope: :year,
                          conditions: -> { where(parent_subscription_id: nil) },
                          message: lambda do |subscription, _data|
                            I18n.t(
                              'custom_error_messages.subscription.member_id.taken',
                              full_name: subscription.member.full_name,
                              year: subscription.year
                            )
                          end
                        },
                        if: -> { parent_subscription_id.nil? },
                        on: :create

  def self.model_name
    Subscription.model_name
  end

  def medical_certificate_required?
    true
  end

  def completion_open?
    year == self.class.current_year
  end

  def build_child_subscription(child_attributes)
    child_subscriptions.new(
      child_attributes.merge(
        type: CampRegistration.sti_name,
        member:,
        year:,
        terms_accepted_at:,
        doctor_certified_at:
      )
    )
  end

  def description
    @description ||= courses.map(&:title).join(', ')
  end

  def available_courses
    @available_courses ||= category_id.present? ? Course.active.where(category_id:).order(:created_at) : Course.none
  end

  def suitable_categories
    member.nil? ? Category.none : Category.suitable_for_age(member.age(year))
  end

  def courses_category
    @courses_category ||= courses.first&.category
  end

  def category
    return @category if defined?(@category)

    @category = Category.find_by(id: category_id)
  end
end
