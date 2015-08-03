require 'rake/testtask'
require "bundler/setup"
Bundler::GemHelper.install_tasks

task 'test:functional:server' do
  require 'rubygems'
  require 'httparty'

  puts 'Starting test server...'
  $server = fork {exec 'ruby', '-I', 'lib', 'test/test_server.rb'}
  begin
    HTTParty.get 'http://localhost:4000/ping'
  rescue
    sleep 1
    retry
  end
  puts 'Test server started...'
end

END {
  if $server
    puts 'Shutting down test server...'
    Process.kill 'TERM', $server
  end
}

task :default => :'test:functional:server'
