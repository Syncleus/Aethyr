require 'aethyr/core/util/marshaller'
require 'aethyr/core/util/hydration'
require 'wisper'

class Publisher
  include Aethyr::Core::Storage::Hydration
  include Marshaller[:@observer_peers, :@local_registrations]
  include Wisper::Publisher

  volatile :@local_registrations
end
