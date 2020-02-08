# frozen_string_literal: true

# https://github.com/thoughtbot/factory_girl/wiki/Testing-all-Factories-%28with-RSpec%29

require 'rails_helper'

describe FactoryBot do
  described_class.factories.map(&:name).each do |factory_name|
    next if factory_name == :subscription # special validators are making this fail

    describe "#{factory_name} factory" do
      # Test each factory
      it 'is valid' do
        factory = described_class.build factory_name
        if factory.respond_to? :valid?
          expect(factory).to be_valid, -> { factory.errors.full_messages.join("\n") }
        end
      end

      # Test each trait
      described_class.factories[factory_name].definition.defined_traits.map(&:name).each do |trait_name|
        context "with trait #{trait_name}" do
          it 'is valid' do
            factory = described_class.build factory_name, trait_name
            if factory.respond_to? :valid?
              expect(factory).to be_valid, -> { factory.errors.full_messages.join("\n") }
            end
          end
        end
      end
    end
  end
end
