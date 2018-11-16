require './inits/init'

configure :development do
  Bundler.require(:default)
end

logger  = Logger.new("./deploy/log/#{MainApp.environment}.log",CONF_LOG_SIZE)
def logger.write(msg)
  self << msg
end
def logger.puts(msg)
  self.write(msg+"\n")
end

def logger.flush
end

configure :production do
  $stderr = logger
  $stdout = logger
end

use Rack::CommonLogger, logger

class AppLog
  def initialize(app,logger)
    @app, @logger = app, logger
  end
  def call(env)
    env["mainapp.logger"] = @logger
    @app.call(env)
  end
end
use AppLog, logger

run MainApp
