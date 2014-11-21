module Sequel
  module Plugins
    # DefaultsSetter only sets default value when it is new instance
    # That means the instance taken from from DB does not set the default value
    # This one sets it
    # Usage:
    #    Sequel::Model.plugin :defaults_setter_custom
    #    Album.set_default_value_custom :name "default_value"
    module DefaultsSetterCustom
      def self.apply(model,*)
        model.instance_variable_set(:@default_values_custom, {})
      end
      def self.configure(model, column_name = nil, value = nil)
        if column_name.nil?.! then
          model.set_default_values_custom(column_name,value)
        end
      end
      module ClassMethods
        attr_reader :default_values_custom
        Plugins.inherited_instance_variables(self, :@default_values_custom=>:hash_dup)
        def set_default_values_custom(column_name, value)
          @default_values_custom[column_name] = value
        end
      end
      module InstanceMethods
        def [](k)
          if self.class.default_values_custom.has_key?(k) and values[k].nil? then
            self.class.default_values_custom[k]
          else
            super
          end
        end
      end
    end
  end
end
