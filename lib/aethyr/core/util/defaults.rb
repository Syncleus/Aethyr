module Defaults
  @@defaults = {}

  def self.defaults
    @@defaults
  end

  def self.included(klazz)
    klazz.extend(ClassMethods)
  end

  def load_defaults
    @@defaults.each do |klazz, local_defaults|
      if self.kind_of? klazz
        local_defaults.each do |default|
          attribute = default[:attribute]
          block = default[:block]
          if not instance_variable_defined?(attribute)
            self.set_default(attribute, &block)
          end
        end
      end
    end
  end

  private

  def set_default(attribute)
    value = yield self
    self.instance_variable_set(attribute, value)
  end

  module ClassMethods
    def default(attribute_raw, &block)
      default_exists = Defaults.defaults.key? self
      local_defaults = default_exists ? Defaults.defaults[self] : []

      attribute = "@".concat(attribute_raw.to_s).to_sym

      local_defaults.push({:attribute => attribute, :block => block})
      Defaults.defaults[self] = local_defaults if not default_exists
    end
  end
end
