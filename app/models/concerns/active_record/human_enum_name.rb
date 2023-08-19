# frozen_string_literal: true

module ActiveRecord
  module HumanEnumName
    # rubocop:disable Metrics/MethodLength
    def enum(name = nil, values = nil, **options)
      super(name, values, **options)

      definitions = options.slice!(:_prefix, :_suffix, :_scopes, :_default)

      definitions.each do |definition_key, definition_values|
        define_singleton_method "#{definition_key}_options" do
          definition_values.map do |key, _value|
            {
              value: key.to_s,
              label: human_enum_name(definition_key, key)
            }
          end
        end

        define_method "#{definition_key}_text" do
          public_send(definition_key).presence && self.class.human_enum_name(definition_key, public_send(definition_key))
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    def human_enum_name(enum_name, enum_value)
      raise ArgumentError, "#{enum_name} is not a defined enum for #{model_name}" unless defined_enums.key?(enum_name.to_s)

      unless defined_enums[enum_name.to_s].key?(enum_value)
        raise ArgumentError,
              "#{enum_value} is not a listed enum value for given enum #{enum_name}. Listed values are: #{defined_enums[enum_name.to_s].keys.to_sentence}"
      end

      enum_i18n_key = enum_name.to_s.pluralize
      I18n.translate!("activerecord.attributes.#{model_name.i18n_key}.#{enum_i18n_key}.#{enum_value}")
    rescue I18n::MissingTranslationData
      enum_value.to_s.titleize
    end
    # rubocop:enable Metrics/AbcSize
  end
end
