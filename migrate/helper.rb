
module Sequel
  class Database
    CUSTOM_EXTRA_BLOCKS = {
      base: lambda{|x|
        primary_key :id
        DateTime :created_at, index:true, null:false
        DateTime :updated_at, index:true, null:false
      },
      env: lambda{|x|
        String :remote_host, size:72
        String :remote_addr, size:48
        String :user_agent, size:255
      },
      thread: lambda{|x|
        DateTime :last_comment_date, index: true, comment:"スレッドに最後に書き込んだ日時"
        foreign_key :last_comment_user_id, :users, on_delete: :set_null, comment: "スレッドに最後に書き込んだユーザ"
        Integer :comment_count, default:0, comment:"コメント数(毎回aggregateするのは遅いのでキャッシュ)"
      },
      comment: lambda{|thread|
        lambda{|x|
          String :body, text:true, null:false, comment:"内容"
          String :user_name, size:24, null:false, comment:"書き込んだ人の名前"
          String :real_name, size:24, comment:"内部的な名前と書き込んだ名前が違う場合に使用"
          foreign_key :thread_id, thread, null:false, on_delete: :cascade
          foreign_key :user_id, :users, on_delete: :set_null
        }
      },
      patch: lambda{|table,table_pk|
        lambda{|x|
          Integer :revision, null:false
          String :patch, text:true, null:false, comment:"差分情報"

          foreign_key :user_id, :users, on_delete: :set_null
          foreign_key table_pk, table, on_delete: :cascade  
          index [:revision, table_pk], unique:true
        }
      },
      image: lambda{|x|
          String :path, size:255, null:false, unique: true
          Integer :width, null:false
          Integer :height, null:false
          String :format, size:50
          foreign_key :album_item_id, :album_items, null:false, unique:true, on_delete: :cascade
      }
    }
    def create_table_custom(name, extra_blocks, options=OPTS, &block)
      create_table(name, options.merge(charset:"utf8")){
        extra_blocks.each{|b|
          if b.is_a?(Symbol) then
            instance_eval(&CUSTOM_EXTRA_BLOCKS[b])
          elsif b.is_a?(Array) then
            instance_eval(&(CUSTOM_EXTRA_BLOCKS[b[0]].call(*b[1..-1])))
          else
            raise Exception.new("#{b.class} is not supported for extra block in #{name}")
          end
        }
        instance_eval(&block) if block
      }
    end
  end
  # this code adds sequel to insert comments
  # see lib/sequel/database/schema_methods.rb and lib/sequel/adapters/shared/mysql.rb
  module MySQL
    module DatabaseMethods
      COLUMN_DEFINITION_ORDER.insert(COLUMN_DEFINITION_ORDER.index(:auto_increment)+1,:comment)
      def column_definition_comment_sql(sql, column)
        sql << " COMMENT #{literal(column[:comment])}" if column.include?(:comment)
      end
      # http://stackoverflow.com/questions/4470108/when-monkey-patching-a-method-can-you-call-the-overridden-method-from-the-new-i
      original_create_table_sql = instance_method(:create_table_sql)
      define_method(:create_table_sql){ |name, generator, options = OPTS |
        comment = options.fetch(:comment, nil)
        "#{original_create_table_sql.bind(self).(name,generator,options)}#{ " COMMENT='#{comment}'" if comment }"
      }
    end
  end
end
