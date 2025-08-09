# frozen_string_literal: true

class FormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Context
  include ActionView::Helpers::TagHelper

  SWITCH_LABEL_DEFAULT_CLASSES = %w[
    pt-0.5
  ].freeze

  SWITCH_INPUT_DEFAULT_CLASSES = %w[
    peer
    opacity-0
    h-0
    w-0
    z-[-1]
  ].freeze

  SWITCH_SLIDER_DEFAULT_CLASSES = %w[
    bg-gray-200
    peer-checked:bg-slate-800
    relative
    inline-flex
    flex-shrink-0
    h-6
    w-11
    border-2
    border-transparent
    rounded-full
    cursor-pointer
    transition-colors
    ease-in-out
    duration-200
    focus:outline-none
    focus:ring-2
    focus:ring-offset-2
    focus:ring-indigo-500
    after:translate-x-0
    after:peer-checked:translate-x-5
    after:pointer-events-none
    after:inline-block
    after:h-5
    after:w-5
    after:rounded-full
    after:bg-white
    after:shadow
    after:transform
    after:ring-0
    after:transition
    after:ease-in-out
    after:duration-200
  ].freeze

  def error_for(attribute, full_messages: false)
    return unless object.errors[attribute].any?

    @template.content_tag(:ul, class: 'list-disc pl-5 text-sm text-red-700') do
      if full_messages
        object.errors.full_messages_for(attribute).each do |message|
          @template.concat @template.content_tag(:li, message)
        end
      else
        object.errors[attribute].each do |message|
          @template.concat @template.content_tag(:li, message)
        end
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def switch(method, options = {}, checked_value = '1', unchecked_value = '0')
    label_options = options.delete(:label_options) || {}

    options[:class] = class_names(SWITCH_INPUT_DEFAULT_CLASSES, options[:class])
    slider_class = options.delete(:slider_class)

    @template.tag.label class: class_names(SWITCH_LABEL_DEFAULT_CLASSES, label_options[:class]) do
      @template.concat(
        check_box(method, options, checked_value, unchecked_value)
      )
      @template.concat(
        @template.tag.span(
          class: class_names(SWITCH_SLIDER_DEFAULT_CLASSES, slider_class),
          role: :switch,
          aria: options[:aria]
        )
      )
    end
    # rubocop:enable Metrics/MethodLength
  end

  private

  def switch_label(label_name)
    @template.tag.span(class: 'text-sm font-medium text-gray-900') { label_name }
  end

  def switch_hint(hint)
    @template.tag.span(class: 'text-sm font-normal text-gray-500') { hint }
  end

  def switch_aria_options(label_name, hint, _method)
    aria_options ||= { disabled: false }
    aria_options[:labelledby] ||= label_name
    aria_options[:describedby] ||= hint

    aria_options
  end
end
