require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module InventoryCommand
  class << self
    #Shows the inventory of the player.
    def inventory(event, player, room)
      player.output(player.show_inventory)
    end
    
    def inventory_help(event, player, room)
      player.output <<'EOF'
Command: Inventory
Syntax: INVENTORY

Displays what you are holding and wearing.

'i' and 'inv' are shortcuts for inventory.


See also: TAKE, DROP, WEAR, REMOVE
EOF
    end
  end

  class InventoryHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["i", "inv", "inventory"])
    end

    def input_handle(input, player)
      e = case input
      when /^(i|inv|inventory)$/i
        { :action => :inventory }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:InventoryCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^(i|inv|inventory)$/i
        { :action => :inventory_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:InventoryCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(InventoryHandler)
end