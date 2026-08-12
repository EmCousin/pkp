# frozen_string_literal: true

class NormalizeLegacyUserCountries < ActiveRecord::Migration[8.1]
  def up
    normalize_known_country_names
    normalize_country_codes
    clear_invalid_countries
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def country_codes
    @country_codes ||= YAML.safe_load_file(Rails.root.join('config/country_codes.yml'))
  end

  def normalize_known_country_names
    execute <<~SQL.squish
      UPDATE users
      SET country = CASE lower(btrim(country))
        #{country_cases}
        ELSE country
      END
      WHERE country IS NOT NULL
        AND lower(btrim(country)) IN (#{quoted_country_names})
    SQL
  end

  def normalize_country_codes
    execute <<~SQL.squish
      UPDATE users
      SET country = upper(btrim(country))
      WHERE country IS NOT NULL
        AND length(btrim(country)) = 2
    SQL
  end

  def clear_invalid_countries
    execute <<~SQL.squish
      UPDATE users
      SET country = NULL
      WHERE country IS NOT NULL
        AND btrim(country) <> ''
        AND upper(btrim(country)) NOT IN (#{quoted_country_codes})
    SQL
  end

  def country_cases
    country_codes.map do |country, code|
      "WHEN #{connection.quote(country)} THEN #{connection.quote(code)}"
    end.join(' ')
  end

  def quoted_country_names
    country_codes.keys.map { connection.quote(it) }.join(', ')
  end

  def quoted_country_codes
    TZInfo::Country.all_codes.map { connection.quote(it) }.join(', ')
  end
end
