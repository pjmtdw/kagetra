# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/ut_karuta' do
    def access_control_allow_all
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'POST'
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    end
    options '/form' do
      access_control_allow_all
    end
    post '/form' do
      access_control_allow_all
      begin
        UtKarutaForm.create(@json)
        {message:"success"}
      rescue Exception => e
        status 500
        logger.warn e.message
        logger.puts e.backtrace.join("\n")
        {message:e.message}
      end
    end
  end
  get '/ut_karuta_list_form' do
    page = (params[:page] || 1).to_i
    @list = UtKarutaForm.order(Sequel.desc(:created_at)).paginate(page, 50)
    haml :ut_karuta_list_form
  end
end