# frozen_string_literal: true

namespace :pennylane do
  desc 'List accounts still carrying the backfilled placeholder name'
  task find_placeholder_customers: :environment do
    users = User.with_placeholder_name.order(:id)

    if users.none?
      puts 'No account has a placeholder name.'
      next
    end

    puts "#{users.count} account(s) with a placeholder name:"
    users.each do |user|
      puts "  id=#{user.id} email=#{user.email} pennylane_customer_id=#{user.pennylane_customer_id || 'none'}"
    end
  end
end
