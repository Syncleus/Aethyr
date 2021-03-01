module Defaults
  @@defaults = {}

  def self.defaults
    @@defaults
  end

  def self.included(klazz)
    klazz.extend(ClassMethods)
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

  module ClassMethods
    def default(attribute_raw, &block)
      default_exists = Defaults.defaults.key? self.name.to_s
      local_defaults = default_exists ? Defaults.defaults[self.name.to_s] : []

      attribute = "@".concat(attribute_raw.to_s).to_sym

      local_defaults.push({:attribute => attribute, :block => block})
      Defaults.defaults[self.name.to_s] = local_defaults if not default_exists
    end
  end
end

class Foo
  include Defaults
  default(:bar) {"foobar"}

  def initialize
    load_defaults
  end

  def bar
    @bar
  end

  def self.check_df
    @@defaults
  end

  def local_df
    @@defaults
  end
end
