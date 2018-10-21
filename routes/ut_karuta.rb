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

    get '/list' do
      page = (params[:page] || 1).to_i
      UtKarutaForm.order(Sequel.desc(:created_at)).paginate(page, 30)
    end
    post '/update_status/:id/:status' do
      UtKarutaForm.first(id:params[:id]).update_status(@user.name,params[:status].to_sym)
    end
  end
  get '/ut_karuta_list_form' do
    haml_wrap '公式フォーム受け取り'
  end
end
