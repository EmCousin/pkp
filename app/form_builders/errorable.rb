# frozen_string_literal: true

module Errorable
  def error_for(attribute, full_messages: false)
    return unless object.errors[attribute].any?

    @template.content_tag(:ul, class: 'list-disc pl-5 text-sm text-red-700') do
      if full_messages
        error_full_messages_for(attribute)
      else
        error_messages_for(attribute)
      end
    end
  end

  private

  def error_full_messages_for(attribute)
    object.errors.full_messages_for(attribute).each do |message|
      @template.concat @template.content_tag(:li, message)
    end
  end

  def error_messages_for(attribute)
    object.errors[attribute].each do |message|
      @template.concat @template.content_tag(:li, message)
    end
  end
end
