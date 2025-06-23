#Load this file to require all objects.


# Core objects - main directory files
require 'aethyr/core/objects/game_object'
require 'aethyr/core/objects/area'
require 'aethyr/core/objects/armor'
require 'aethyr/core/objects/container'
require 'aethyr/core/objects/corpse'
require 'aethyr/core/objects/door'
require 'aethyr/core/objects/equipment'
require 'aethyr/core/objects/exit'
require 'aethyr/core/objects/inventory'
require 'aethyr/core/objects/living'
require 'aethyr/core/objects/mobile'
require 'aethyr/core/objects/player'
require 'aethyr/core/objects/portal'
require 'aethyr/core/objects/prop'
require 'aethyr/core/objects/reactor'
require 'aethyr/core/objects/room'
require 'aethyr/core/objects/scroll'
require 'aethyr/core/objects/weapon'

# Core objects - traits subdirectory
require 'aethyr/core/objects/traits/expires'
require 'aethyr/core/objects/traits/has_inventory'
require 'aethyr/core/objects/traits/lexicon'
require 'aethyr/core/objects/traits/location'
require 'aethyr/core/objects/traits/news'
require 'aethyr/core/objects/traits/openable'
require 'aethyr/core/objects/traits/position'
require 'aethyr/core/objects/traits/readable'
require 'aethyr/core/objects/traits/reacts'
require 'aethyr/core/objects/traits/respawns'
require 'aethyr/core/objects/traits/sittable'
require 'aethyr/core/objects/traits/wearable'

# Core objects - info subdirectory
require 'aethyr/core/objects/info/calendar'
require 'aethyr/core/objects/info/info'
require 'aethyr/core/objects/info/terrain'

# Core objects - info/flags subdirectory
require 'aethyr/core/objects/info/flags/flag'

# Core objects - info/skills subdirectory
require 'aethyr/core/objects/info/skills/skill'

# Core objects - attributes subdirectory
require 'aethyr/core/objects/attributes/attribute'
require 'aethyr/core/objects/attributes/blind'

# Extension objects
require 'aethyr/extensions/objects/chair'
require 'aethyr/extensions/objects/clothing_items'
require 'aethyr/extensions/objects/dagger'
require 'aethyr/extensions/objects/key'
require 'aethyr/extensions/objects/lever'
require 'aethyr/extensions/objects/newsboard'
require 'aethyr/extensions/objects/parchment'
require 'aethyr/extensions/objects/sword'

#Dir.glob('aethyr/core/objects/*.rb').each do |f|
#  require f[0..-4] unless  f[0,1] == '~'
#end