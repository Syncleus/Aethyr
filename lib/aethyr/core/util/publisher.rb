require 'aethyr/core/util/marshaller'
require 'wisper'

class Publisher
  include Marshaller[:@observer_peers, :@local_registrations]
  include Wisper::Publisher
end