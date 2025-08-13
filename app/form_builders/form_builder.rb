# frozen_string_literal: true

class FormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Context
  include ActionView::Helpers::TagHelper
  include Errorable
  include Switchable
end
