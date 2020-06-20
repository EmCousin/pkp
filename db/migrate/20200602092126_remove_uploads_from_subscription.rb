class RemoveUploadsFromSubscription < ActiveRecord::Migration[6.0]
  def change
    remove_column :subscriptions, :medical_certificate, :string
    remove_column :subscriptions, :signed_form, :string
  end
end
