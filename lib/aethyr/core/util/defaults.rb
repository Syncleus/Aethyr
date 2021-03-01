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
      if not instance_variable_defined?(attribute)
        self.set_default(attribute, &block)
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

  attr_reader :sex

  default(:bar) {"foobar"}
  default(:baz) { |this| this.instance_variable_get(:@bar).concat(" and baz") }
  #default(:sex) {"m"}
  default(:gender) do |this|
    if this.sex == 'm'
      "Lexicon::Gender::MASCULINE"
    elsif this.sex == 'f'
      "Lexicon::Gender::FEMININE"
    else
      "Lexicon::Gender::NEUTER"
    end
  end

  def initialize
    @dummy_var = "this is just so something exists"
    @sex = 'm'
    load_defaults
  end

  def local_failbar
    @failbar
  end

  def local_bar
    @bar
  end

  def self.check_df
    @@defaults
  end

  def local_df
    @@defaults
  end

  def class_vars_proxy
    self.class.instance_variables
  end

  def local_baz
    @baz
  end

  def local_sex
    @sex
  end

  def local_gender
    @gender
  end
end

puts "check_df"
puts Foo.check_df

puts "local_df"
foo = Foo.new
puts foo.local_df

puts "Defaults::defaults"
puts Defaults::defaults

#puts "foo.defaults"
#puts foo.defaults

puts "local_bar"
puts foo.local_bar

puts "local_failbar"
puts foo.local_failbar

puts "instance vars"
puts foo.instance_variables

puts "class vars"
puts Foo.instance_variables

puts "class vars proxy"
puts foo.class_vars_proxy

puts "local_baz"
puts foo.local_baz

puts "local_sex"
puts foo.local_sex

puts "local_gender"
puts foo.local_gender
