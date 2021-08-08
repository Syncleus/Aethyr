require 'aethyr/core/actions/commands/command_action'

module Aethyr
  module Extend
    class EmoteAction < Aethyr::Extend::CommandAction
      def initialize(actor, **data)
        super(actor, **data)
      end

      protected

      #Run an emote.
      def make_emote event, player, room, &block
        g = GenericEmote.new(event, player, room)
        g.instance_eval(&block)
        if g.return_event && (g.return_event.respond_to? :has_key?)
          g.set_post #add postfix
          log "Doing event" , Logger::Ultimate
          room.out_event g.return_event
        end
      end


      #Provides little DSL to easily create emotes.
      class GenericEmote

        attr_reader :return_event

        def initialize(event, player, room)
          @event = event.dup
          @self[:message_type] = :chat
          @self[:player] = player
          @player = player
          @room = room
          @post = self[:post]
          @object = nil
          @return_event = nil
          find_target
        end

        #If there is no target, return the given block.
        def no_target
          return if @return_event

          if @object.nil?
            @return_event = yield
          end
        end

        #If the target is the player, return the given block.
        def self_target
          return if @return_event

          if @object == @player
            @return_event = yield
          end
        end

        #If there is a target, return the given block.
        def target
          return if @return_event

          unless @object.nil?
            @return_event = yield
          end
        end

        #If nothing else matches, return the given block.
        def default
          @return_event = yield
        end

        #Provide output to show player.
        def to_player output
          @self[:to_player] = output
          @event
        end

        #Provide output to show others.
        def to_other output
          @self[:to_other] = output
          @event
        end

        #Provide output to show target.
        def to_target output
          @self[:to_target] = output
          @event
        end

        #Provide output to show blind others.
        def to_blind_other output
          @self[:to_blind_other] = output
          @event
        end

        #Provide output to show deaf others.
        def to_deaf_other output
          @self[:to_deaf_other] = output
          @event
        end

        #Provide output to show blind target.
        def to_blind_target output
          @self[:to_blind_target] = output
          @event
        end

        #Provide output to show deaf target.
        def to_deaf_target output
          @self[:to_deaf_target] = output
          @event
        end

        #Appends suffix to emote.
        def set_post
          return if not @post
          [:to_player, :to_other, :to_target, :to_blind_other, :to_blind_target, :to_deaf_other, :to_deaf_target].each do |t|
            if @return_self[t]
              if @return_self[t][-1,1] == "."
                @return_self[t][-1] = ""
              end

              if @post[0,1] == ","
                @return_self[t] << @post
              else
                @return_self[t] << " " << @post
              end

              unless ["!", "?", ".", "\"", "'"].include? @post[-1,1]
                @return_self[t] << "."
              end
            end
          end
        end

        private

        #Find target for emote.
        def find_target
          if @object.nil? and @self[:object]
            @object = @room.find(@self[:object]) || @player.search_inv(@self[:object])
            @self[:target] = @object
          end
        end
      end
    end
  end
end
