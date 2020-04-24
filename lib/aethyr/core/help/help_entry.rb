module Aethyr
  module Core
    module Help
      module HelpEntry
        attr_reader :redirect, :content, :see_also, :command, :aliases

        def initialize(command, redirect: nil, content: nil, see_also: nil, aliases: nil, syntax_formats: nil)
          #do some validity checking on the arguments
          raise "Redirect cant be defined alongside other arguments" unless redirect.nil? || (content.nil? && see_also.nil? && aliases.nil? and syntax_formats.nil?)
          raise "either content or redirect must be defined" if redirect.nil? && content.nil?
          raise "syntax_format must be defined when content is defined" if (not content.nil?) && (syntax_formats.nil? || syntax_formats.empty?)

          @command = command
          @redirect = redirect
          @content = content
          @see_also = see_also
          @aliases = aliases
          @syntax_formats = syntax_formats
          @see_also = [] if @see_also.nil? && (not @content.nil?)
          @aliases = [] if @aliases.nil? && (not @content.nil?)
        end
      end

    end
  end
end
