web: bundle exec bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq -t 10 -C config/sidekiq.yml
postdeploy: bundle exec rails db:migrate
