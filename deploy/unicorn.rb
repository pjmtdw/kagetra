require 'securerandom'
@cur = File.dirname(File.realpath(__FILE__))
@dir = File.realpath(File.join(@cur,".."))
worker_processes 4
working_directory @dir

timeout 60

listen "#{@cur}/sock/unicorn.sock", backlog: 64
pid "#{@cur}/pid/unicorn.pid"
stderr_path "#{@cur}/log/unicorn.err.log"
stdout_path "#{@cur}/log/unicorn.out.log"

@session_secret = SecureRandom.base64(48)
before_fork do | server, worker |
  # share session_secret between worker processes
  ENV["RACK_SESSION_SECRET"] = @session_secret
end
