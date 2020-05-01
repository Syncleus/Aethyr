#Load this file to require all event modules.

#Dir.foreach('lib/aethyr/commands') do |f|
#  if f[0,1] == '.' || f[0,1] == '~'
#    next
#  end
#
#  require "aethyr/commands/#{f[0..-4]}"
#end
#require 'aethyr/core/actions/commands/admin'
#require 'aethyr/core/actions/commands/clothing'
#require 'aethyr/core/actions/commands/combat'
#require 'aethyr/core/actions/commands/communication'
#require 'aethyr/core/actions/commands/custom'
#require 'aethyr/core/actions/commands/emote'
#require 'aethyr/core/actions/commands/generic'
#require 'aethyr/core/actions/commands/martial_combat'
#require 'aethyr/core/actions/commands/mobiles'
#require 'aethyr/core/actions/commands/movement'
#require 'aethyr/core/actions/commands/news'
#require 'aethyr/core/actions/commands/settings'
#require 'aethyr/core/actions/commands/weapon_combat'

require 'require_all'
require_all 'lib/aethyr/core/actions/commands/'
require_all 'lib/aethyr/extensions/actions/commands/'
