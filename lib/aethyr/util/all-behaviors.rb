#Load this file to require all traits.

#Dir.foreach('lib/aethyr/traits') do |f|
#  if f[0,1] == '.' || f[0,1] == '~'
#    next
#  end
#
#  require "aethyr/traits/#{f[0..-4]}"
#end
require 'aethyr/traits/expires'
require 'aethyr/traits/hasinventory'
require 'aethyr/traits/news'
require 'aethyr/traits/openable'
require 'aethyr/traits/position'
require 'aethyr/traits/pronoun'
require 'aethyr/traits/reacts'
require 'aethyr/traits/readable'
require 'aethyr/traits/respawns'
require 'aethyr/traits/sittable'
require 'aethyr/traits/wearable'