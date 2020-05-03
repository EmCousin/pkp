class AddUploadsToSubscription < ActiveRecord::Migration[6.0]
  def change
    add_column :subscriptions, :medical_certificate, :string
    add_column :subscriptions, :signed_form, :string
  end
end
