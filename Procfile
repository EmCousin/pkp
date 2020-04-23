web: bundle exec bin/rails server -p $PORT -e $RAILS_ENV
watcher: RAILS_ENV=production NODE_ENV=production bundle exec bin/webpack --watch --colors --progress
worker: bundle exec sidekiq -t 10 -C config/sidekiq.yml
