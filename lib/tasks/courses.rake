namespace :courses do
  desc 'Seed default courses'
  task seed: :environment do
    def create_courses!(category, weekdays, slots, capacity)
      weekdays.to_a.each do |weekday_name, weekday_index|
        slots.each do |slot|
          title = "#{weekday_name.capitalize} #{category} #{slot}"
          puts "Creating course #{title}..."
          Course.create!(
            title: title,
            description: title,
            capacity: 60,
            weekday: weekday_index,
            category: category
          )
          puts "Course #{title} created."
        end
      end
    end

    Course::CATEGORIES.each do |category|
      case category
      when 'Adulte'
        weekdays = Course.weekdays.to_a[0..4]
        slots = ['19h - 20h30']
      when 'Adulte Féminin'
        weekdays = Course.weekdays.to_a[0..0]
        slots = ['19h - 20h30']
      when 'Adolescent (13 - 15 ans)', 'Adolescent (10 - 12 ans)'
        weekdays = Course.weekdays.select { |k, v| v.in?([3, 6]) }
        slots = ['14h15 - 15h30', '15h30 - 16h45']
      when 'Kidz (6 - 9 ans)'
        weekdays = Course.weekdays.to_a[5..5]
        slots = ['11h - 12h']
      end

      create_courses!(category, weekdays, slots, 60)
    end
  end
end

