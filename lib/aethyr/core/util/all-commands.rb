#Load this file to require all event modules.

#Dir.foreach('lib/aethyr/commands') do |f|
#  if f[0,1] == '.' || f[0,1] == '~'
#    next
#  end
#
#  require "aethyr/commands/#{f[0..-4]}"
#end
#require 'aethyr/core/commands/admin'
#require 'aethyr/core/commands/clothing'
#require 'aethyr/core/commands/combat'
#require 'aethyr/core/commands/communication'
#require 'aethyr/core/commands/custom'
#require 'aethyr/core/commands/emote'
#require 'aethyr/core/commands/generic'
#require 'aethyr/core/commands/martial_combat'
#require 'aethyr/core/commands/mobiles'
#require 'aethyr/core/commands/movement'
#require 'aethyr/core/commands/news'
#require 'aethyr/core/commands/settings'
#require 'aethyr/core/commands/weapon_combat'

require 'require_all'
require_all 'lib/aethyr/core/commands/'
require_all 'lib/aethyr/extensions/commands/'
