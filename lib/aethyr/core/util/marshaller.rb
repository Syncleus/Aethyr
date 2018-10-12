class Marshaller < Module
  class << self
    alias [] new
  end

  def initialize *ignored_ivars
    @ignored = ignored_ivars
  end

  def included base
    base.class_exec @ignored do |ignored|
      @@ignored = ignored

      def marshal_load vars
        vars.each do |attr, value|
          instance_variable_set(attr, value) unless @@ignored.include?(attr)
        end
      end

      def marshal_dump
        instance_variables.reject{|m| @@ignored.include? m}.inject({}) do |vars, attr|
          vars[attr] = instance_variable_get(attr)
          vars
        end
      end
    end
  end
end