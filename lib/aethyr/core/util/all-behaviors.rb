#Load this file to require all traits.

#Dir.foreach('lib/aethyr/traits') do |f|
#  if f[0,1] == '.' || f[0,1] == '~'
#    next
#  end
#
#  require "aethyr/traits/#{f[0..-4]}"
#end

# Individual require statements for all traits files
require 'aethyr/core/objects/traits/expires'
require 'aethyr/core/objects/traits/has_inventory'
require 'aethyr/core/objects/traits/lexicon'
require 'aethyr/core/objects/traits/location'
require 'aethyr/core/objects/traits/news'
require 'aethyr/core/objects/traits/openable'
require 'aethyr/core/objects/traits/position'
require 'aethyr/core/objects/traits/reacts'
require 'aethyr/core/objects/traits/readable' 
require 'aethyr/core/objects/traits/respawns'
require 'aethyr/core/objects/traits/sittable'
require 'aethyr/core/objects/traits/wearable'