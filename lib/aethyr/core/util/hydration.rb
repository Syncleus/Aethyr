module Aethyr
  module Core
    module Storage
      module Hydration
        module Volatile
          @@volatile ||= []

          def volatile(*attrs)
            @@volatile = [] if @@volatile.nil?
            @@volatile += attrs
            @@volatile.uniq!
          end

          def volatile_vars
            return @@volatile
          end
        end

        # removes all volatle data but provides it as a map for restoration in rehydrate
        def dehydrate
          volatile_data = {}
          self.class.volatile_vars.each do |attr|
            if self.instance_variable_defined?(attr)
              volatile_data[attr] = self.instance_variable_get(attr)
              begin
                self.remove_instance_variable(attr)
              rescue NameError
              end
            end
          end
          return volatile_data
        end

        def rehydrate(volatile_data)
          return if volatile_data.nil?
          volatile_data.each do |attr, data|
            self.instance_variable_set(attr, data) if self.class.volatile_vars.include? attr
          end
        end

        def self.included(klass)
          klass.extend(Volatile)
        end
      end
    end
  end
end
