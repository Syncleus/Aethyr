module Defaults
  @@defaults = {}

  def self.default(attribute_raw, &block)
    default_exists = @@defaults.key? self.name.to_s
    local_defaults = default_exists ? @@defaults[self.name.to_s] : []

    attribute = "@".concat(attribute_raw.to_s).to_sym

    local_defaults.push({:attribute => attribute, :block => block})
    @@defaults[self.name.to_s] = local_defaults if not default_exists
  end

  def load_defaults
    return if not @@defaults.key? self.class.name.to_s
    local_defaults = @@defaults[self.class.name.to_s]
    local_defaults.each do |default|
      attribute = default[:attribute]
      block = default[:block]
      if defined?(attribute).nil?
        self.set_default(attribute, &block)
      end
    end
  end

  private

  def set_default(attribute)
    self.set_instance_variable(attribute, yield)
  end
end
