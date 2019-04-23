# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  get '/img/*' do |splat|
    send_file("./static/img/#{splat}")
  end
  namespace '/api' do
    def getBoardMessageName(mode)
      halt_wrap 403, "invalid board message mode." unless ["user","shared"].include?(mode)
      "board_message_" + mode
    end

    get '/board_message/:mode' do
      name = getBoardMessageName(params[:mode])
      cnf = MyConf.first(name: name)
      if cnf.nil? then {message: ""} else cnf.value end
    end
    post '/board_message/:mode' do
      with_update{
        name = getBoardMessageName(params[:mode])
        MyConf.update_or_create({name: name}, {value: {message: @json['message']}})
      }
    end
  end
end
