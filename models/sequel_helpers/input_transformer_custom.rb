module Sequel
  module Plugins
    # just like Sequel::Plugins::InputTransformer, but instead of doing blacklist-type filtering,
    # this plugin can explicitly set column name to filter
    # Example1:
    #   Album.plugin :input_transformer_custom
    #   Album.add_input_transformer_custom(:name){|v| v.reverse}
    #   album = Album.name(name:'foo')
    #   album.name # => 'oof'
    #
    # Example2:
    #   Sequel::Model.plugin :input_transformer_custom # all models will use this plugin
    #   Album.add_input_transformer_custom(:name){|v| v.reverse} 
    module InputTransformerCustom
      def self.apply(model,*)
        model.instance_eval do
          @input_transformer_customs = Hash.new{Array.new}
        end
      end
      def self.configure(model, column_name = nil, &block)
        if column_name and block then
          model.add_input_transformer_custom(column_name, &block)
        end
      end
      module ClassMethods
        # { column_name: [transformer1, transformer2, ...] }
        attr_reader :input_transformer_customs
        Plugins.inherited_instance_variables(self, :@input_transformer_customs => :hash_dup)
        def add_input_transformer_custom(column_name, &block)
          @input_transformer_customs[column_name].push(block)
        end
      end
      module InstanceMethods
        def []=(k,v)
          model.input_transformer_customs[k].each{|block|
            block.call(v)
          }
        end
      end
    end
  end
end
