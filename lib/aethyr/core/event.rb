require 'ostruct'

#Events are an OpenStruct-like object to make it simpler (less typing) to create commands.
#They can also be treated as hashes (which makes them backwards-compatible with code that has not
#been updated yet.)
#
#Events are required to have the following fields:
#
# -name: The name of the module (as a symbol) which handles the event.
# -action: The name of the method (as a symbol) which handles the event.
# -player: The GameObject the event is concerning.
#
#The following are also commonly used:
#
# -at
# -target
# -object
# -to
#
#The rest are dependent on the actual event. The best place to see these are in CommandParser or the event modules themselves.
#
class Event < OpenStruct

  #name must be a symbol which is the same as the module which handles the event.
  #
  #An optional hash can be passed in as well to define attributes.
  def initialize(type, **data)
    super(**data)
    self.type = type
  end

  #This is the event type. <i>Depreciated.</i>
  def type
    @table[:type]
  end

  def type= value
    @table[:type] = value
  end

  # #Retrieve an attribute.
  # #
  # #Note: it is preferable to use accessor methods instead, like Event.new(:Combat).name
  # def [] index
  #   @table[index.to_sym]
  # end

  # #Set an attribute.
  # #
  # #Note: it is preferable to use accessor methods instead, like Event.new(:Combat).target = "bob"
  # def []= index, value
  #   #self.new_ostruct_member(index)

  #   self[index.to_sym] = value
  #   @table[index.to_sym] = value
  #   self
  # end

  #Takes a hash and adds them just like initialize does.
  def << args
    unless args.nil?
      args.each do |k,v|
        @table[k.to_sym] = v
        # ------------------------------------------------------------------
        # Ruby 3.3+ removed the private `OpenStruct#new_ostruct_member` helper
        # that earlier versions used to create dynamic accessors.  To keep
        # backward-/forward-compatibility we detect its presence at runtime
        # and fall back to an explicit `define_singleton_method` strategy
        # when necessary (Open/Closed Principle – the public contract of
        # Event remains unchanged regardless of upstream evolution).
        # ------------------------------------------------------------------
        if respond_to?(:new_ostruct_member, true)
          # Older Rubies – delegate to the original helper.
          send(:new_ostruct_member, k)
        else
          # Newer Rubies – eagerly install reader & writer on the *singleton*
          # class so that later calls like `event.target` still work.
          singleton_class.class_eval do
            define_method(k) { @table[k.to_sym] }
            define_method("#{k}=") { |val| @table[k.to_sym] = val }
          end
        end
      end
    end
    self
  end

  #Copied from OpenStruct.inspect, but don't recursively inspect things (that is bad for Events, trust me).
  def to_s
    str = "#<#{self.class}"

    Thread.current[InspectKey] ||= []
    if Thread.current[InspectKey].include?(self) then
      str << " ..."
    else
      first = true
      for k,v in @table
        str << "," unless first
        first = false

        Thread.current[InspectKey] << v
        begin
          if k == :attached_events
            str << "#{k}=<Events...>"
          else
            str << " #{k}=#{v}"
          end
        ensure
          Thread.current[InspectKey].pop
        end
      end
    end

    str << ">"
  end

  #Attach another event to this one. Attached commands will be run immediately after
  #the event they are attached to.
  def attach_event event
    self.attached_events ||= []
    self.attached_events << event
  end
end
