# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/mobile/bbs' do
    get '/:page' do
      @threads = call_api(:get,"/api/bbs/threads",{page:params[:page]})
      mobile_haml :bbs
    end
    def mobile_bbs_response(res)
      if res.is_a?(Hash) and res["_error_"]
        res["_error_"]
      else
        mobile_haml <<-HEREDOC
書き込みました
%a(href='bbs') [戻る]
        HEREDOC
      end
    end
    post '/thread' do
      para = params.select_attr("body","title").merge(public:params[:public].to_s.empty?.!)
      res = call_api(:post,"/api/bbs/thread",para)
      mobile_bbs_response(res)
    end
    post '/item/:thread_id' do
      para = params.select_attr("thread_id","body")
      res = call_api(:post,"/api/bbs/item",para)
      mobile_bbs_response(res)
    end
  end
  get '/mobile/bbs' do
    call env.merge("PATH_INFO" => "/mobile/bbs/1")
  end
end
