# coding: utf-8
module Aethyr
  module Core
    module Help
      class HelpLibrary
        def initialize
          @help_registry = {}
        end

        def entry_register(new_entry)
          @help_registry[new_entry.topic] = new_entry
        end

        def entry_deregister(topic)
          @help_registry.delete(topic)
        end

        def search_topics(search_term)
          return @help_registry.keys.grep /#{search_term}/
        end

        def topics
          return @help_registry.keys.dup
        end

        def lookup_topic(topic)
          return @help_registry[topic]
        end

        def render_topic(topic)
          redirected_from = ""
          entry = lookup_topic(topic)

            return "Topic #{topic} has no entry, try help with no arguments" if entry.nil?

          while entry.redirect? do
            redirected_from = "→ redirected from #{topic}\n\n" if redirected_from.empty?
            entry = lookup_topic(entry.redirect)
          end

          rendered = redirected_from

          rendered += "Aliases: " + entry.aliases.join(", ") + "\n" unless entry.aliases.empty?

          syntaxes = []
          entry.syntax_formats.each do |syntax|
            syntaxes.push "Syntax: #{syntax}"
          end
          rendered += syntaxes.join("\n")
          rendered += "\n\n" unless syntaxes.empty? && aliases.empty?

          rendered += entry.content + "\n"

          rendered += "See also: " + entry.see_also.join(", ") + "\n" unless entry.see_also.empty?

          return rendered
        end
      end
    end
  end
end
