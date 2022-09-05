# frozen_string_literal: true

class BlobValidator < ::ActiveModel::EachValidator
  # Validates that the specified ActiveStorage attributes
  # match the conditions as defined in the :blob options
  #
  #   class Person < ActiveRecord::Base
  #     has_one_attached  :avatar
  #     has_one_attached  :favicon
  #     has_one_attached  :cover_picture
  #     has_many_attached :video_portfolios
  #
  #     validates :avatar, :cover_picture, blob: { image: true }
  #     validates :avatar, blob: {
  #                          representable: {
  #                            width: { greater_than_or_equal_to: 256 },
  #                            height: { greater_than_or_equal_to: 256 }
  #                          }
  #                        }
  #     validates :favicon, blob: { image: true, representable: { square: true } }
  #     validates :video_portfolios, blob: { video: true, size_range: 1024..4096 }
  #   end

  include ActiveSupport::NumberHelper

  def validate_each(record, attribute, values)
    raise TypeError unless active_storage?(values)
    return unless values.attached?

    Array(values).each do |value|
      validate_size_range(record, attribute, value)
      validate_content_type(record, attribute, value)
      validate_representation(record, attribute, value)
    end
  end

  private

  def active_storage?(values)
    Array(values).all?(ActiveStorage::Attached)
  end

  def validate_size_range(record, attribute, value)
    return if options[:size_range].blank?

    validate_min_size(record, attribute, value)
    validate_max_size(record, attribute, value)
  end

  def validate_min_size(record, attribute, value)
    return if options[:size_range].min < value.blob.byte_size

    record.errors.add(attribute, :min_size_error, min_size: number_to_human_size(options[:size_range].min))
  end

  def validate_max_size(record, attribute, value)
    return if options[:size_range].max > value.blob.byte_size

    record.errors.add(attribute, :max_size_error, max_size: number_to_human_size(options[:size_range].max))
  end

  def validate_content_type(record, attribute, value)
    return if options[:content_type].nil? || valid_content_type?(value.blob)

    record.errors.add(attribute, :content_type)
  end

  def valid_content_type?(blob)
    case options[:content_type]
    when Regexp then options[:content_type].match?(blob.content_type)
    when Array then options[:content_type].include?(blob.content_type)
    when Symbol then blob.public_send("#{options[:content_type]}?")
    else options[:content_type] == blob.content_type
    end
  end

  def validate_representation(record, attribute, value)
    return if options[:representable].blank?

    record.errors.add(attribute, :representable) && return unless value.representable?

    validate_image_representation(record, attribute, value) if value.image?
  end

  def validate_image_representation(record, attribute, value)
    return unless (file = record.attachment_changes[value.name]&.attachable)

    image = Vips::Image.new_from_file(file.path)
    value.metadata.merge!(if rotated_image?(image)
                            { height: image.width, width: image.height }
                          else
                            { height: image.height, width: image.width }
                          end)

    validate_image_dimension(record, attribute, value, :width)
    validate_image_dimension(record, attribute, value, :height)
    validate_image_square(record, attribute, value)
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def validate_image_dimension(record, attribute, value, dimension_attribute)
    return unless options.dig(:representable, dimension_attribute)

    if (limit = options.dig(:representable, dimension_attribute, :greater_than))
      record.errors.add(attribute, "#{dimension_attribute}_too_short".to_sym, value: limit) if value.metadata[dimension_attribute] <= limit
    elsif (limit = options.dig(:representable, dimension_attribute, :greater_than_or_equal_to))
      record.errors.add(attribute, "#{dimension_attribute}_too_short_strict".to_sym, value: limit) if value.metadata[dimension_attribute] < limit
    elsif (limit = options.dig(:representable, dimension_attribute, :less_than))
      record.errors.add(attribute, "#{dimension_attribute}_too_long".to_sym, value: limit) if value.metadata[dimension_attribute] >= limit
    elsif (limit = options.dig(:representable, dimension_attribute, :less_than_or_equal_to))
      record.errors.add(attribute, "#{dimension_attribute}_too_long_strict".to_sym, value: limit) if value.metadata[dimension_attribute] > limit
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def validate_image_square(record, attribute, value)
    return unless options.dig(:representable, :square) == true
    return if value.metadata[:width] == value.metadata[:height]

    record.errors.add(attribute, :square)
  end

  ROTATIONS = /Right-top|Left-bottom|Top-right|Bottom-left/
  def rotated_image?(image)
    ROTATIONS === image.get('exif-ifd0-Orientation')
  rescue Vips::Error
    false
  end
end
