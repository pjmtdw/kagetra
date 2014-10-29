
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
      }
    }
    def create_table_custom(name, extra_blocks, options=OPTS, &block)
      create_table(name, options.merge(charset:"utf8")){
        extra_blocks.each{|b|
          instance_eval(&CUSTOM_EXTRA_BLOCKS[b])
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
