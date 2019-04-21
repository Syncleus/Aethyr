require 'aethyr/core/objects/living'
require 'aethyr/core/commands/command_parser'
require 'aethyr/core/objects/traits/has_inventory'
require 'aethyr/core/help/syntax'
# TODO : Delete the next to requires
require 'aethyr/extensions/skills/map'
require 'aethyr/extensions/skills/kick'

#Base class for all players.
class Player < LivingObject

  @@satiety = {
    120 => "completely stuffed",
    110 => "full and happy",
    100 => "full and happy",
    90 => "satisfied",
    80 => "not hungry",
    70 => "slightly hungry",
    60 => "slightly hungry",
    50 => "peckish",
    40 => "hungry",
    30 => "very hungry",
    20 => "famished",
    10 => "starving",
    0 => "literally dying of hunger"
  }

  @@health = {
    100 => "at full health",
    90 => "a bit bruised",
    80 => "a little beat up",
    70 => "slightly injured",
    60 => "quite injured",
    50 => "slightly wounded",
    40 => "wounded in several places",
    30 => "heavily wounded",
    20 => "bleeding profusely and in serious pain",
    10 => "nearly dead",
    0 => "dead"

  }

  attr_reader :admin, :color_settings
  attr_accessor :use_color, :reply_to, :page_height, :layout

  #Create a new player object with the given socket connection. You must also pass in a game_object_id and a room, although if you pass in nil for game_object_id it will auto-generate one for you.
  def initialize(connection, game_object_id, room, *args)
    super(game_object_id, room, *args)
    @player = connection
    @admin = false
    @skills = { :wield => 50, :thrust => 50, :simple_block => 50}
    @last_target = nil
    @color_settings = nil
    @use_color = nil
    @word_wrap = 120
    @page_height = nil
    @deaf = false
    @blind = false
    @reply_to = nil
    @prompt_shown = false
    @layout = :basic
    @player.display.layout(layout: @layout, in_combat: info.in_combat)

    info.stats.satiety = 120
    map_skill = Aethyr::Extensions::Skills::Map.new(self.game_object_id)
    kick_skill = Aethyr::Extensions::Skills::Kick.new(self.game_object_id)
    info.skills = { map_skill.id => map_skill, kick_skill.id => kick_skill}
    info.explored_rooms = Set.new [room]
    map_skill.add_xp 750
  end

  def color_settings= new_color_settings
    @color_settings = new_color_settings
    @player.display.color_settings = @color_settings
  end

  #Searches inventory and equipment for item.
  def has? item
    inventory.find(item) || equipment.find(item)
  end

  def menu options, answers = nil, &block
    @player.ask_menu options, answers, &block
  end

  #Displays more paginated text to player.
  def more
    @player.more
  end

  def deaf?
    @deaf
  end

  def blind?
    @blind
  end

  #Sets balance
  def balance= val
    #was = @balance
    @balance = val
    #self.output "You recover your balance." if @balance and not was
  end

  #Direct access to the PlayerConnection for this Player.
  def io
    @player
  end

  #Returns word_wrap length.
  def word_wrap
    @word_wrap
  end

  #Sets word_wrap length
  def word_wrap= size
    @player.word_wrap = size
    @word_wrap = size
  end

  #Sends an event to the player.
  def out_event(event)
    if event[:target] == self and event[:player] != self
      if self.blind? and not self.deaf?
        self.output event[:to_blind_target]
      elsif self.deaf? and not self.blind?
        self.output event[:to_deaf_target]
      elsif self.deaf? and self.blind?
        self.output event[:to_deafandblind_target]
      else
        self.output event[:to_target]
      end
    elsif event[:player] == self
      self.output event[:to_player]
    else
      if self.blind? and not self.deaf?
        self.output event[:to_blind_other]
      elsif self.deaf? and not self.blind?
        self.output event[:to_deaf_other]
      elsif self.deaf? and self.blind?
        self.output event[:to_deafandblind_other]
      else
        self.output event[:to_other]
      end
    end
  end

  #Outputs a message to the Player. Used for all communication to Player.
  def output(message, no_newline = false, message_type: :main)
    return if message.nil?
    begin
      if message.is_a? Array
        message = message.join("\r\n")
      end

      @player.say(message, no_newline, message_type: message_type) unless (@player.nil? or @player.closed?)
    rescue Exception => e
      log "Unable to send message to #{@name}"
      log e.inspect
      log(e.backtrace.join("\n"), Logger::Normal, true)
      quit
    end
  end

  #Just outputs a message to the player that we don't know what
  #to do with the method call.
  def method_missing(*args)
    super
    self.output("Don't know what do to with: #{args.inspect}")
  end

  #Handles the input from the Player. Basically, it just takes the
  #input, feeds it to the CommandParser, then sends the event
  #(if any) to the Manager.
  def handle_input(input)
    if input.nil? or input.chomp.strip == ""
      return
    end

    if not alive
      self.output "You are dead. You can't do much of anything."
      return
    end

    clean_input = input.downcase.strip
    self.output("Help topics available: ", false) if (clean_input.eql? "help") or (clean_input.eql? "help topics")
    broadcast(:player_input, {:publisher => self, :input => input})
    event = CommandParser.parse(self, input)
    self.output(" ", false) if (clean_input.eql? "help") or (clean_input.eql? "help topics")

    if event.nil?
      if input
        doc = Syntax.find(input.strip.split[0].downcase)
        if doc
          output doc
        else
          output 'Not sure what you mean by that.'
        end
      end
    elsif @asleep and event[:action] != 'wake'
      output 'You cannot do that when you are asleep!'
    else
      changed
      notify_observers(event)
    end
  end

  #The player's next input will go to the block.
  def expect(&block)
    @player.expect(&block)
  end

  #Puts the player in the Editor. The block will be called
  #with the contents of the Editor when the Player exits it.
  def editor(buffer = [], limit = 100, &block)
    @player.start_editor(buffer, limit, &block)
  end

  #Outputs contents of inventory
  def show_inventory
    inv_out = "You are holding "

    inv_out << @inventory.show

    inv_out << ".\n" << @equipment.show
  end

  #Returns a String with the long_desc of the Player and a description of their visible equipment.
  def long_desc
    desc = "" << @long_desc << "\n"
    desc << @equipment.show(self)

    return desc
  end

  #Closes the network connection to the Player.
  def quit
    @player.close unless @player.nil? or @player.closed?
  end

  #Returns descriptive health level.
  def health
    @@health[((info.stats.health.to_f / info.stats.max_health) * 100).to_i / 10 * 10]
  end

  #Returns descriptive hunger level.
  def satiety
    @@satiety[(info.stats.satiety.to_f / 10).to_i * 10]
  end

  def take_damage amount, type = :health
    super
  end

  def update_display
    @player.display.refresh_watch_windows(self)
  end

  def run
    super
    if info.stats.health < info.stats.max_health - 10
      info.stats.health += 10
    elsif info.stats.health < info.stats.max_health
      info.stats.health = info.stats.max_health
    end
    update_display
  end
end
