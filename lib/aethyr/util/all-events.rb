#Load this file to require all event modules.

#Dir.foreach('lib/aethyr/events') do |f|
#  if f[0,1] == '.' || f[0,1] == '~'
#    next
#  end
#
#  require "aethyr/events/#{f[0..-4]}"
#end
require 'aethyr/events/admin'
require 'aethyr/events/clothing'
require 'aethyr/events/combat'
require 'aethyr/events/communication'
require 'aethyr/events/custom'
require 'aethyr/events/emote'
require 'aethyr/events/generic'
require 'aethyr/events/martial_combat'
require 'aethyr/events/mobiles'
require 'aethyr/events/movement'
require 'aethyr/events/news'
require 'aethyr/events/settings'
require 'aethyr/events/weapon_combat'