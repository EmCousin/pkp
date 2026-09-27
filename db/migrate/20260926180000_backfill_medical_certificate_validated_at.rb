# frozen_string_literal: true

class BackfillMedicalCertificateValidatedAt < ActiveRecord::Migration[8.1]
  # Before this feature, an annual subscription auto-confirmed as soon as it was paid, had
  # accepted terms, and had a self-declared medical certificate (doctor_certified_at) — with
  # no admin sign-off. `medical_certificate_validated_at` did not exist yet, so every one of
  # those already-confirmed subscriptions would otherwise start showing a false "pending
  # validation" state, and an admin clicking "Valider" on one would re-send the confirmation
  # email long after the fact.
  #
  # We backfill medical_certificate_validated_at with doctor_certified_at: it is the moment the
  # member's declaration (and, in practice, the review implied by the subscription having been
  # confirmed under the old rules) was recorded, so historical records read as validated at the
  # time they were originally accepted rather than at migration time.
  #
  # Only rows that hold their own doctor-certified declaration are touched, via raw SQL so no
  # model callbacks or validations run. Inherited descendants (subscriptions that reuse a prior
  # season's certificate) need no update here: Subscriptions::MedicalCertificate#source resolves
  # them from their source row, so they become validated? automatically once that source row is
  # backfilled.
  def up
    execute <<~SQL.squish
      UPDATE subscriptions
      SET medical_certificate_validated_at = doctor_certified_at
      WHERE type = 'AnnualSubscription'
        AND status = 1
        AND doctor_certified_at IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE subscriptions
      SET medical_certificate_validated_at = NULL
      WHERE type = 'AnnualSubscription'
        AND status = 1
        AND doctor_certified_at IS NOT NULL
    SQL
  end
end
