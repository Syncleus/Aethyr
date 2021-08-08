require 'ostruct'

module Kernel
  #Creates a future event and adds it to the EventHandler
  def after time, unit = :sec, event = nil, &block
    case unit
    when :sec
      seconds = time
    when :min
      seconds = time * 60
    when :hour
      seconds = time * 3600
    when :day
      seconds = time * 3600 * 24
    when :week
      seconds = time * 3600 * 24 * 7
    when :month
      seconds = time * 3600 * 24 * 7 * 30
    else
      seconds = time
    end

    if event
      f = CommandParser.future_event(self, seconds, event)

      if block_given?
        log "Ignoring block for future event."
      end
    else
      f = CommandParser.future_event(self, seconds, &block)
    end

    $manager.update f
    f
  end
end



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
  def initialize(type, **kwargs)
    kwargs[:type] = type
    super kwargs
  end

  #Retrieve an attribute.
  #
  #Note: it is preferable to use accessor methods instead, like Event.new(:Combat).name
  def [] index
    @table[index.to_sym]
  end

  #Set an attribute.
  #
  #Note: it is preferable to use accessor methods instead, like Event.new(:Combat).target = "bob"
  def []= index, value
    self.new_ostruct_member(index)
    @table[index.to_sym] = value
    self
  end

  #Takes a hash and adds them just like initialize does.
  def << args
    unless args.nil?
      args.each do |k,v|
        @table[k.to_sym] = v
        new_ostruct_member(k)
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
