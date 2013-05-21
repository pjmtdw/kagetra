@cur = File.dirname(File.realpath(__FILE__))
@dir = File.realpath(File.join(@cur,".."))
worker_processes 1
working_directory @dir

timeout 60

listen "#{@cur}/sock/unicorn.sock", :backlog => 64
pid "#{@cur}/pid/unicorn.pid"
stderr_path "#{@cur}/log/unicorn.err.log"
stdout_path "#{@cur}/log/unicorn.out.log"
