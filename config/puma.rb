
workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 1)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 9294
environment ENV['RACK_ENV'] || 'production'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  #   # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  Mongoid.load!("config/mongoid.yml", :production)
end
  #