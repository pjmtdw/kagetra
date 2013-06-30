# -*- coding: utf-8 -*-
module MiscHelpers
  def get_user
    user = User.first(id: session[:user_id], token: session[:user_token])
    if user.nil? then
      halt 403,'Login Required.'
    end
    user
  end
  def dm_response
    begin
      yield
    rescue DataMapper::SaveFailureError => e
      msg = e.resource.errors.full_messages().join("\n")
      logger.warn msg
      $stderr.puts msg
      {_error_: msg}
    rescue Exception => e
      logger.warn e.message
      $stderr.puts e.message

      bt = e.backtrace[0...12].join("\n")
      logger.puts bt
      $stderr.puts bt
      {_error_: e.message }
    end
  end

  PERMANENT_COOKIE_NAME="kagetra.permanent"
  def get_permanent
    str = request.cookies[PERMANENT_COOKIE_NAME]
    if str.to_s.empty? then
      return nil
    end
    return JSON.parse(Base64.strict_decode64(str))
  end

  def set_permanent(data)
    str = Base64.strict_encode64(data.to_json)
    response.set_cookie(PERMANENT_COOKIE_NAME,
                        value: str,
                        path: "/",
                        expires: (Date.today + 90).to_time)
  end
  def delete_permanent
    response.delete_cookie(PERMANENT_COOKIE_NAME)
  end
end
