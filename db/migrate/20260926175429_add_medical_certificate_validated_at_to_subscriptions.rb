# frozen_string_literal: true

class AddMedicalCertificateValidatedAtToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :medical_certificate_validated_at, :datetime
  end
end
