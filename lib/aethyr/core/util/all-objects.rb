#Load this file to require all objects.

require 'require_all'
require_all 'lib/aethyr/core/objects'
require_all 'lib/aethyr/extensions/objects'

#Dir.glob('aethyr/core/objects/*.rb').each do |f|
#  require f[0..-4] unless  f[0,1] == '~'
#end