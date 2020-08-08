require 'rails_helper'

describe Members::Searchable, type: :model do
  subject { member }

  let(:member) { create :member }

  describe '.search' do
    it 'performs a search query' do
      expect(Member.search('WHATEVER').to_sql).to eq(
        Member.joins(:user).where(
          'LOWER(first_name) LIKE :search
          OR LOWER(last_name) LIKE :search
          OR LOWER(users.email) LIKE :search
          OR users.phone_number LIKE :search',
          search: "%whatever%"
        ).to_sql
      )
    end

    context "when the query at least partially matches a member's first name" do
      let(:query) { member.first_name[0..2] }

      it 'includes that member' do
        expect(Member.search(query)).to include(member)
      end
    end

    context "when the query at least partially matches a member's last name" do
      let(:query) { member.last_name[0..2] }

      it 'includes that member' do
        expect(Member.search(query)).to include(member)
      end
    end

    context "when the query at least partially matches a member's user email" do
      let(:query) { member.email[0..2] }

      it 'includes that member' do
        expect(Member.search(query)).to include(member)
      end
    end

    context "when the query at least partially matches a member's user phone number" do
      let(:query) { member.phone_number[0..2] }

      it 'includes that member' do
        expect(Member.search(query)).to include(member)
      end
    end

    context 'when the query is blank' do
      let(:query) { '' }

      it 'selects all members' do
        expect(Member.search(query).to_sql).to eq Member.all.to_sql
      end
    end
  end
end

module Members
  module Searchable
    extend ActiveSupport::Concern

    class_methods do
      def search(query)
        return all unless query.present?

        joins(:user).where(
          'LOWER(first_name) LIKE :search
          OR LOWER(last_name) LIKE :search
          OR LOWER(users.email) LIKE :search
          OR users.phone_number LIKE :search',
          search: "%#{query.downcase}%"
        )
      end
    end
  end
end
