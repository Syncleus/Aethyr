# frozen_string_literal: true

###############################################################################
# WorldCoverGenerator                                                          #
# --------------------------------------------------------------------------- #
# Generates a massive, real-world-mirroring virtual world for the Aethyr MUD   #
# using ESA's WorldCover 10 m Land-Cover dataset.                              #
#                                                                              #
# NOTE: This implementation favours readability, maintainability and SOLID    #
# design principles over raw generation speed. Each method is documented in   #
# detail and internal behaviour is fully explained.                            #
###############################################################################

require 'thread'            # Concurrency primitives (Mutex, Queue, Thread)
require 'set'               # For uniqueness tracking
require 'open-uri'          # Remote file access
require 'fileutils'         # Local cache folder handling
require 'logger'            # Lightweight progress output if ncurses is not desired
require 'rexml/document'    # XML parsing for bucket listings
require 'gdal'
require 'etc'

module Aethyr
  module Core
    module Util
      # WorldCoverGenerator orchestrates the download, cache management, and
      # incremental processing of ESA WorldCover raster tiles so that an
      # in-game representation of planet Earth can be constructed.  Download
      # and processing are pipelined: up to MAX_CONCURRENT_DOWNLOADS run in   
      # parallel while the main thread converts completed files into game      
      # entities. Processing has been redesigned to eliminate mutex contention
      # and maximize CPU utilization across all available cores.
      class WorldCoverGenerator
        # ------------------------------------------------------------------- #
        # Constants & configuration                                           #
        # ------------------------------------------------------------------- #

        # The default spatial resolution (edge length in metres per room).
        # Set to 10 m to mirror the native resolution of the input dataset.
        RESOLUTION_METRES = 5000

        # Remote storage settings – direct S3 REST endpoint (not website)
        BUCKET_BASE_URL       = 'https://world-terrain-data.s3.amazonaws.com/'.freeze
        YEAR                  = 2021
        VERSION               = 'v200'.freeze

        # Local on-disk cache for *.tif files. A sibling of the application's
        # existing storage folder so CI caches are preserved across runs.
        CACHE_DIR             = File.expand_path('../../../../worldcover', __dir__)

        # Maximum number of concurrent HTTP streams.
        MAX_CONCURRENT_DL     = 10

        # When set to a positive integer, generation will stop after this
        # number of tiles has been downloaded/processed.  A value of zero
        # (the default) disables the limit and processes every tile that
        # intersects the supplied lat/lon ranges.  This is invaluable when
        # running unit tests or quick local experiments.
        MAX_TILES             = 1
        # Maximum number of concurrent processing threads.
        MAX_CONCURRENT_PROC   = [Etc.nprocessors * 4, 4].max  # Increase from 2x to 4x cores for IO-bound work
        BATCH_SIZE = 10  # Process rooms in batches to reduce queue contention

        # World-cover numeric code → Terrain constant symbol mapping.
        # We purposefully re-use the existing terrain palette to avoid having
        # to extend the public API or alter any game logic that depends on the
        # current set of constants. When a direct translation does not exist
        # we choose the closest semantic match.
        CODE_TO_TERRAIN = {
          10  => :GRASSLAND, # Tree cover → treat as generic grassland
          20  => :GRASSLAND, # Shrubland
          30  => :GRASSLAND, # Grassland
          40  => :GRASSLAND, # Cropland
          50  => :CITY,      # Built-up / urban areas
          60  => :GRASSLAND, # Bare / sparse vegetation
          70  => :TUNDRA,    # Snow & ice → closest existing constant
          80  => :TUNDRA,    # Permanent water bodies
          90  => :GRASSLAND, # Herbaceous wetland
          95  => :GRASSLAND, # Mangroves
          100 => :TUNDRA     # Moss & lichen – tundra-like
        }.freeze

        # Friendly names & description templates for procedural flavour text.
        # The arrays may be extended without touching generation logic.
        NAME_TEMPLATES = {
          GRASSLAND: [
            'Verdant Fields', 'Sea of Grass', 'Rolling Prairie', 'Open Meadow'
          ],
          CITY: [
            'Bustling City Block', 'Concrete Jungle', 'Urban Sprawl', 'Downtown Sector'
          ],
          TUNDRA: [
            'Frozen Expanse', 'Bleak Icefield', 'Snow-Covered Plain', 'Glacial Barrens'
          ]
        }.freeze

        DESCRIPTION_TEMPLATES = {
          GRASSLAND: [
            'Tall grass sways gently in the wind, stretching to the horizon.',
            'You stand amidst endless, rolling grasslands dotted with wildflowers.',
            'The air is fresh and the ground soft underfoot where grass grows thick.'
          ],
          CITY: [
            'Towering structures of glass and steel surround you on every side.',
            'The distant hum of traffic and chatter of crowds fill the vibrant streets.',
            'Neon signs flicker above tightly-packed storefronts in this urban landscape.'
          ],
          TUNDRA: [
            'Snow crunches beneath your boots in this frozen wilderness.',
            'A biting wind whips across an expanse of white as far as the eye can see.',
            'The stark, icy plain glitters under a pale sun, devoid of vegetation.'
          ]
        }.freeze

        # ------------------------------------------------------------------- #
        # Internal data structures for lock-free processing                   #
        # ------------------------------------------------------------------- #

        # Represents processed room data before object creation
        ProcessedRoom = Struct.new(:x, :y, :tile_code, :terrain_sym, :name, :desc, :area_goid) do
          # Generate a unique key for this room's position
          def position_key
            "#{tile_code}:#{x}:#{y}"
          end
        end

        # Represents a connection between two rooms
        RoomConnection = Struct.new(:from_key, :to_key, :direction_from, :direction_to)

        # ------------------------------------------------------------------- #
        # Construction                                                        #
        # ------------------------------------------------------------------- #

        attr_reader :start_room_goid

        # @param manager [Aethyr::Core::Components::Manager] the live Manager
        #   responsible for object lifecycles.
        # @param resolution [Integer] metres per room (≥ 10 and a multiple of
        #   10). Higher values coarsen the grid and therefore reduce the total
        #   number of rooms, mitigating memory usage during a full-planet run.
        # @param max_concurrent_downloads [Integer] number of simultaneous
        #   HTTP GET requests allowed.
        # @param logger [Logger] optional custom logger instance.
        def initialize(manager, resolution: RESOLUTION_METRES,
                       max_concurrent_downloads: MAX_CONCURRENT_DL,
                       max_concurrent_processors: MAX_CONCURRENT_PROC,
                       logger: Logger.new($stdout))
          raise ArgumentError, 'Manager cannot be nil' unless manager
      
          @manager   = manager
          @logger    = logger
          @res       = resolution < 10 ? 10 : resolution
          @max_dl    = [max_concurrent_downloads, 1].max
          @max_proc  = [max_concurrent_processors, 1].max
      
          @download_queue  = Queue.new   # tile_code strings awaiting fetch
          @process_queue   = Queue.new   # local .tif paths awaiting raster-to-rooms
      
          @downloaded      = 0          # tiles fetched & cached this session
          @processed       = 0          # tiles converted into Aethyr rooms
      
          @tile_total      = nil        # lazy initialised once queue is populated
          @mutex           = Mutex.new  # protects @downloaded/@processed counters
          
          # Lock-free data structures for high-performance parallel processing
          @processed_rooms = Queue.new    # ProcessedRoom structs ready for object creation
          @room_connections = Queue.new   # RoomConnection structs for linking
          @room_lookup = {}              # position_key -> room_goid mapping (synchronized via @room_lookup_mutex)
          @room_lookup_mutex = Mutex.new # Only used for final room lookup updates
        end

        ######################################################################
        # Public API                                                         #
        ######################################################################

        # Kick off the end-to-end pipeline. This call is blocking until the
        # last tile finishes processing, but download and CPU work overlap.
        #
        # For a complete Earth run the default ranges of −90…90 latitude and
        # −180…180 longitude are used. Pass smaller ranges when experimenting
        # locally to keep generation time sensible (e.g. a single tile).
        #
        # @param lat_range [Range]   latitude bounds in integral degrees
        # @param lon_range [Range]   longitude bounds in integral degrees
        def build_world(lat_range: (-90..89), lon_range: (-180..179))
          populate_download_queue(lat_range, lon_range)
      
          @logger.info("Tiles to download: #{@tile_total}. Starting #{@max_dl} download threads and #{@max_proc} processing threads …")
      
          # Start all threads
          download_threads = spawn_download_pool
          processing_threads = spawn_processing_pool
          object_creation_thread = spawn_object_creation_thread
          room_connection_thread = spawn_room_connection_thread
      
          # Monitor thread progress and CPU usage
          monitor_thread = Thread.new do
            while download_threads.any?(&:alive?) || 
                  processing_threads.any?(&:alive?) ||
                  object_creation_thread.alive? ||
                  room_connection_thread.alive?
              
              sleep 5
              @logger.info("CPU utilization monitoring: #{@downloaded}/#{@tile_total} downloaded, #{@processed}/#{@tile_total} processed")
            end
          end
      
          # Wait for all work to complete
          download_threads.each(&:join)
          processing_threads.each(&:join)
          object_creation_thread.join
          room_connection_thread.join
          monitor_thread.join
          
          @logger.info("World generation complete! Total rooms created: #{@room_lookup.size}")
        end

        ######################################################################
        # Download stage                                                     #
        ######################################################################

        private

        # Build the download queue using the authoritative list of objects in
        # the bucket, thereby avoiding 404s for non-existent tiles. The list
        # is paginated so we loop until the bucket indicates completion.
        def populate_download_queue(lat_range, lon_range)
          @logger.info('Discovering available tiles from S3 bucket …')

          continuation_marker = nil
          total_discovered    = 0

          limit = MAX_TILES.positive? ? MAX_TILES : nil

          catch(:limit_reached) do
            loop do
              listing_xml = fetch_bucket_listing(continuation_marker)
              doc         = REXML::Document.new(listing_xml)

              doc.elements.each('//Contents/Key') do |el|
                key = el.text
                next unless key =~ /ESA_WorldCover_10m_\d{4}_#{VERSION}_(?<code>[NS]\d{2}[EW]\d{3})_Map\.tif$/

                tile_code = Regexp.last_match(:code)

                lat_deg, lon_deg = decode_tile_origin(tile_code)

                next unless lat_range.cover?(lat_deg) && lon_range.cover?(lon_deg)

                @download_queue << tile_code
                total_discovered += 1

                # Respect optional tile limit.
                if limit && total_discovered >= limit
                  throw :limit_reached
                end
              end

              truncated = doc.elements['//IsTruncated']&.text == 'true'

              break unless truncated

              continuation_marker = doc.elements.to_a('//Contents/Key').last.text
            end
          end

          @tile_total = total_discovered
          if limit
            @logger.info("Discovered #{@tile_total} tiles matching requested bounds (capped at #{limit}).")
          else
            @logger.info("Discovered #{@tile_total} tiles matching requested bounds.")
          end
        end

        # Retrieve one page of the bucket listing. We use the classic v1 API
        # for compatibility which relies on the optional `marker` parameter
        # to page through keys lexicographically.
        def fetch_bucket_listing(marker = nil)
          uri = URI(BUCKET_BASE_URL)
          params = {}
          params['prefix'] = "#{VERSION}/#{YEAR}/map/"
          params['marker'] = marker unless marker.nil?
          uri.query = URI.encode_www_form(params) unless params.empty?

          @logger.debug("Listing bucket with marker=#{marker.inspect}")
          URI.open(uri).read
        end

        # Decode numeric lat/lon origins from a tile code string.
        def decode_tile_origin(code)
          lat_sign = code[0] == 'S' ? -1 : 1
          lat_deg  = lat_sign * code[1, 2].to_i

          lon_sign = code[3] == 'W' ? -1 : 1
          lon_deg  = lon_sign * code[4, 3].to_i

          [lat_deg, lon_deg]
        end

        # Create and return a list of download worker threads.
        def spawn_download_pool
          (1..@max_dl).map do |_i|
            Thread.new do
              loop do
                tile_code = nil

                @mutex.synchronize do
                  begin
                    tile_code = @download_queue.pop(true)
                  rescue ThreadError
                    # queue empty – all work handed out
                    tile_code = nil
                  end
                end

                break unless tile_code

                begin
                  tif_path = fetch_tile(tile_code)
                  @process_queue << tif_path
                  increment_download_counter
                rescue StandardError => e
                  @logger.error("Download failed for #{tile_code}: #{e.message}")
                end
              end
            end
          end
        end

        # Downloads a single GeoTIFF to CACHE_DIR unless it already exists.
        # Returns the absolute local filesystem path.
        def fetch_tile(tile_code)
          filename = "ESA_WorldCover_10m_#{YEAR}_#{VERSION}_#{tile_code}_Map.tif"
          filepath = File.join(CACHE_DIR, filename)

          FileUtils.mkdir_p(CACHE_DIR)

          return filepath if File.exist?(filepath) && File.size?(filepath)

          url = File.join(BUCKET_BASE_URL, VERSION, YEAR.to_s, 'map', filename)
          @logger.debug("Fetching #{url}")

          # Open-URI follows redirects automatically; we stream straight to disk
          URI.open(url) do |remote|
            File.open(filepath, 'wb') { |f| IO.copy_stream(remote, f) }
          end

          filepath
        end

        # ------------------------------------------------------------------- #
        # Processing stage - completely redesigned for lock-free operation   #
        # ------------------------------------------------------------------- #

        # Create a pool of processing threads that work independently without
        # shared state contention. Each thread processes complete tiles and
        # outputs ProcessedRoom and RoomConnection data to lock-free queues.
        def spawn_processing_pool
          (1..@max_proc).map do |_i|
            Thread.new do
              # Thread-local batch collection to reduce queue contention
              local_processed_rooms = []
              local_room_connections = []
              
              loop do
                tif_path = nil

                # Non-blocking pop with minimal lock time
                begin
                  tif_path = @process_queue.pop(true)
                rescue ThreadError
                  # If we have accumulated batches, push them before checking exit condition
                  if !local_processed_rooms.empty? || !local_room_connections.empty?
                    flush_local_batches(local_processed_rooms, local_room_connections)
                    local_processed_rooms = []
                    local_room_connections = []
                  end
                  
                  # Queue empty, check if downloads are still running
                  break if @downloaded >= @tile_total
                  sleep 0.01 # Reduced sleep time to check more frequently
                  next
                end

                if tif_path
                  tile_code = File.basename(tif_path)[/[NS]\d{2}[EW]\d{3}/]
                  @logger.info("Processing #{tile_code} …")
                  
                  # Process the tile with local batching
                  process_tile_with_batching(tif_path, local_processed_rooms, local_room_connections)
                  
                  # If batches are large enough, flush them to the main queues
                  if local_processed_rooms.size >= BATCH_SIZE || local_room_connections.size >= BATCH_SIZE * 4
                    flush_local_batches(local_processed_rooms, local_room_connections)
                    local_processed_rooms = []
                    local_room_connections = []
                  end
                  
                  increment_process_counter
                end
              end
              
              # Final flush of any remaining items
              flush_local_batches(local_processed_rooms, local_room_connections) unless local_processed_rooms.empty?
            end
          end
        end

        # Process a single tile without any shared state access.
        # This eliminates the mutex bottleneck entirely by deferring
        # all room creation and connection to separate phases.
        def process_tile_lockfree(tif_path)
          ds         = Gdal::Gdal.open(tif_path)
          band       = ds.get_raster_band(1)
          width      = ds.RasterXSize
          height     = ds.RasterYSize

          tile_code = File.basename(tif_path)[/[NS]\d{2}[EW]\d{3}/]
          step_px   = @res / 10
          
          # Create area data that will be used by object creation thread
          area_name = "Area #{File.basename(tif_path, '.tif')}"
          area_data = { tile_code: tile_code, name: area_name }
          
          # Helper for generating flavour text – memoised per thread
          flavour_cache = {}

          # Pre-compute sample positions to avoid generating the same ranges
          sample_x = (0...width).step(step_px).to_a

          # Process each room position and generate ProcessedRoom data
          (0...height).step(step_px).each do |y|
            sample_x.each do |x|
              # Read single pixel value
              pixel_data = band.read_raster(x, y, 1, 1)
              code = pixel_data.getbyte(0)
              terrain_sym = CODE_TO_TERRAIN[code] || :GRASSLAND
              terrain_const = ::Terrain.const_get(terrain_sym)

              name, desc = flavour_cache[terrain_sym] ||= [
                NAME_TEMPLATES[terrain_sym]&.sample || terrain_const.name.capitalize,
                DESCRIPTION_TEMPLATES[terrain_sym]&.sample || "An unremarkable #{terrain_const.room_text}."
              ]

              # Create processed room data (no mutex needed)
              processed_room = ProcessedRoom.new(x, y, tile_code, terrain_sym, name, desc, nil)
              @processed_rooms << processed_room

              # Generate connection data for later processing (no mutex needed)
              # WEST/EAST linkage
              if x > 0  # Has western neighbor within same tile
                west_key = "#{tile_code}:#{x - step_px}:#{y}"
                connection = RoomConnection.new(west_key, processed_room.position_key, 'east', 'west')
                @room_connections << connection
              end

              # NORTH/SOUTH linkage  
              if y > 0  # Has northern neighbor within same tile
                north_key = "#{tile_code}:#{x}:#{y - step_px}"
                connection = RoomConnection.new(north_key, processed_room.position_key, 'south', 'north')
                @room_connections << connection
              end
            end
          end

        ensure
          # Release GDAL resources deterministically
          ds = nil
        end

        # Process a single tile with local batching to reduce queue contention
        def process_tile_with_batching(tif_path, local_rooms, local_connections)
          ds         = Gdal::Gdal.open(tif_path)
          band       = ds.get_raster_band(1)
          width      = ds.RasterXSize
          height     = ds.RasterYSize

          tile_code = File.basename(tif_path)[/[NS]\d{2}[EW]\d{3}/]
          step_px   = @res / 10
          
          # Helper for generating flavour text – memoised per thread
          flavour_cache = {}

          # Pre-compute sample positions
          sample_x = (0...width).step(step_px).to_a
          
          # Process in chunks to improve memory locality
          chunk_size = [height / @max_proc, step_px * 10].max
          
          (0...height).step(chunk_size).each do |chunk_y|
            max_y = [chunk_y + chunk_size, height].min
            
            (chunk_y...max_y).step(step_px).each do |y|
              # Read the entire row at once for better performance
              row_data = band.read_raster(0, y, width, 1)
              
              sample_x.each do |x|
                # Get pixel value from pre-read row
                code = row_data.getbyte(x)
                terrain_sym = CODE_TO_TERRAIN[code] || :GRASSLAND
                terrain_const = ::Terrain.const_get(terrain_sym)

                name, desc = flavour_cache[terrain_sym] ||= [
                  NAME_TEMPLATES[terrain_sym]&.sample || terrain_const.name.capitalize,
                  DESCRIPTION_TEMPLATES[terrain_sym]&.sample || "An unremarkable #{terrain_const.room_text}."
                ]

                # Create processed room data and add to local batch
                processed_room = ProcessedRoom.new(x, y, tile_code, terrain_sym, name, desc, nil)
                local_rooms << processed_room

                # Generate connection data for later processing
                # WEST/EAST linkage
                if x > 0  # Has western neighbor within same tile
                  west_key = "#{tile_code}:#{x - step_px}:#{y}"
                  connection = RoomConnection.new(west_key, processed_room.position_key, 'east', 'west')
                  local_connections << connection
                end

                # NORTH/SOUTH linkage
                if y > 0  # Has northern neighbor within same tile
                  north_key = "#{tile_code}:#{x}:#{y - step_px}"
                  connection = RoomConnection.new(north_key, processed_room.position_key, 'south', 'north')
                  local_connections << connection
                end
              end
            end
          end

        ensure
          # Release GDAL resources deterministically
          ds = nil
        end

        # Helper method to flush local batches to main queues
        def flush_local_batches(rooms, connections)
          rooms.each { |room| @processed_rooms << room }
          connections.each { |conn| @room_connections << conn }
        end

        # ------------------------------------------------------------------- #
        # Object creation stage - separate thread for maximum efficiency     #
        # ------------------------------------------------------------------- #

        # Spawn a dedicated thread for creating game objects from processed room data.
        # This allows object creation to proceed in parallel with tile processing
        # while avoiding mutex contention on the Manager.
        def spawn_object_creation_thread
          Thread.new do
            areas_created = {}
            rooms_created = 0
            room_batch = []

            loop do
              # Try to get a batch of rooms at once to reduce queue contention
              begin
                # Get up to BATCH_SIZE rooms at once
                BATCH_SIZE.times do
                  room_batch << @processed_rooms.pop(true)
                end
              rescue ThreadError
                # If we got at least one room, process the batch
                if room_batch.empty?
                  # Queue empty, check if processing is complete
                  break if @processed >= @tile_total
                  sleep 0.01 # Very short sleep to avoid busy-waiting
                  next
                end
              end

              # Process the batch of rooms
              room_batch.each do |processed_room|
                # Create area if not already created for this tile
                unless areas_created[processed_room.tile_code]
                  area = @manager.create_object(
                    Aethyr::Core::Objects::Area,
                    nil,
                    nil,
                    nil,
                    :@name => "Area #{processed_room.tile_code}"
                  )
                  areas_created[processed_room.tile_code] = area.goid
                end

                area_goid = areas_created[processed_room.tile_code]
                area = @manager.get_object(area_goid)

                # Create the room
                room = @manager.create_object(
                  Aethyr::Core::Objects::Room,
                  area,
                  [processed_room.x, processed_room.y],
                  nil,
                  :@name => processed_room.name,
                  :@short_desc => processed_room.desc
                )

                terrain_const = ::Terrain.const_get(processed_room.terrain_sym)
                room.info.terrain.type = terrain_const

                # Update room lookup (minimal mutex usage)
                @room_lookup_mutex.synchronize do
                  @room_lookup[processed_room.position_key] = room.goid
                end

                # Record the very first room as spawn/start location
                @start_room_goid ||= room.goid

                rooms_created += 1
              end
              
              if (rooms_created % 100).zero?
                @logger.debug("Created #{rooms_created} rooms so far...")
              end
              
              # Clear the batch for next iteration
              room_batch.clear
            end

            @logger.info("Object creation complete. Created #{rooms_created} rooms.")
          end
        end

        # ------------------------------------------------------------------- #
        # Room connection stage - separate thread for linking rooms          #
        # ------------------------------------------------------------------- #

        # Spawn a dedicated thread for creating Exit objects between rooms.
        # This runs after room creation and handles all the room linking
        # without any mutex contention on shared processing state.
        def spawn_room_connection_thread
          Thread.new do
            connections_created = 0
            connections_processed = 0
            connection_batch = []
            processed_connections = Set.new # Track which connections we've already processed

            # Wait until some rooms are created before starting to process connections
            until @room_lookup.size > 0
              sleep 0.5
              next
            end

            loop do
              # Try to get a batch of connections at once
              begin
                # Get up to BATCH_SIZE*4 connections at once (connections are smaller objects)
                (BATCH_SIZE * 4).times do
                  connection_batch << @room_connections.pop(true)
                end
              rescue ThreadError
                # If we got at least one connection, process the batch
                if connection_batch.empty?
                  # Queue empty, check if processing is complete and we've processed all rooms
                  if @processed >= @tile_total && @processed_rooms.empty?
                    # Do one final sweep to catch any missed connections
                    @logger.info("Performing final connection sweep with #{@room_lookup.size} rooms...")
                    create_missing_connections
                    break
                  end
                  sleep 0.1 # Slightly longer sleep to reduce CPU usage
                  next
                end
              end

              # Process the batch of connections
              connection_batch.each do |connection|
                connections_processed += 1
                connection_key = "#{connection.from_key}:#{connection.to_key}"
                
                # Skip if we've already processed this connection
                next if processed_connections.include?(connection_key)
                processed_connections.add(connection_key)

                # Look up the room GOIDs (read-only access to lookup hash)
                from_goid = @room_lookup[connection.from_key]
                to_goid = @room_lookup[connection.to_key]

                if from_goid && to_goid
                  # Create bidirectional exits
                  success = link_rooms(from_goid, to_goid, connection.direction_from, connection.direction_to)
                  connections_created += 1 if success
                end
              end

              if (connections_processed % 1000).zero?
                @logger.debug("Processed #{connections_processed} connections, created #{connections_created} exits...")
              end
              
              # Clear the batch for next iteration
              connection_batch.clear
            end

            @logger.info("Room connection complete. Created #{connections_created} exits from #{connections_processed} connections.")
          end
        end

        # Create bidirectional Exit objects between two rooms.
        def link_rooms(room_a_gid, room_b_gid, name_a_to_b, name_b_to_a)
          room_a = @manager.get_object(room_a_gid)
          room_b = @manager.get_object(room_b_gid)
    
          return false if room_a.nil? || room_b.nil?
          
          # Check if exits already exist to avoid duplicates
          return false if room_a.exit(name_a_to_b) || room_b.exit(name_b_to_a)
    
          begin
            # Create exit from room A to room B
            @manager.create_object(
              Aethyr::Core::Objects::Exit,
              room_a,
              nil,
              room_b_gid,
              :@alt_names => [name_a_to_b]
            )
    
            # Create exit from room B to room A
            @manager.create_object(
              Aethyr::Core::Objects::Exit,
              room_b,
              nil,
              room_a_gid,
              :@alt_names => [name_b_to_a]
            )
            
            return true
          rescue StandardError => e
            @logger.error("Failed to create exits between #{room_a_gid} and #{room_b_gid}: #{e.message}")
            return false
          end
        end

        # Add a method to create missing connections by scanning all rooms
        def create_missing_connections
          connections_created = 0
          step_px = @res / 10
          
          # Create a copy of the lookup to avoid modification during iteration
          room_positions = @room_lookup.keys
          
          room_positions.each do |pos_key|
            # Parse the position key
            tile_code, x, y = pos_key.split(':')
            x = x.to_i
            y = y.to_i
            
            # Check for neighbors in all four cardinal directions
            neighbors = [
              { key: "#{tile_code}:#{x + step_px}:#{y}", dir_from: 'east', dir_to: 'west' },
              { key: "#{tile_code}:#{x - step_px}:#{y}", dir_from: 'west', dir_to: 'east' },
              { key: "#{tile_code}:#{x}:#{y + step_px}", dir_from: 'south', dir_to: 'north' },
              { key: "#{tile_code}:#{x}:#{y - step_px}", dir_from: 'north', dir_to: 'south' }
            ]
            
            neighbors.each do |neighbor|
              if @room_lookup[neighbor[:key]]
                from_goid = @room_lookup[pos_key]
                to_goid = @room_lookup[neighbor[:key]]
                
                # Check if the exit already exists
                from_room = @manager.get_object(from_goid)
                if from_room && !from_room.exit(neighbor[:dir_from])
                  success = link_rooms(from_goid, to_goid, neighbor[:dir_from], neighbor[:dir_to])
                  connections_created += 1 if success
                end
              end
            end
          end
          
          @logger.info("Created #{connections_created} missing connections in final sweep")
        end

        ######################################################################
        # Utility helpers                                                    #
        ######################################################################

        # Round a coordinate down to the lower-left corner of its 3° tile.
        def tile_origin(coord_deg)
          (coord_deg / 3.0).floor * 3
        end

        # Build the 4-character lat/lon code used by WorldCover filenames.
        def tile_code(lat, lon)
          lat0 = tile_origin(lat)
          lon0 = tile_origin(lon)

          lat_prefix = lat0.negative? ? 'S' : 'N'
          lon_prefix = lon0.negative? ? 'W' : 'E'

          format('%s%02d%s%03d', lat_prefix, lat0.abs, lon_prefix, lon0.abs)
        end

        # ------------------------------------------------------------------- #
        # Thread-safe metric updates                                         #
        # ------------------------------------------------------------------- #

        def increment_download_counter
          @mutex.synchronize do
            @downloaded += 1
            log_progress
          end
        end

        def increment_process_counter
          @mutex.synchronize do
            @processed += 1
            log_progress
          end
        end

        # Output a simple textual status line. We avoid using external gems
        # like ruby-progressbar so that the generator remains self-contained.
        def log_progress
          percent_dl  = (@downloaded.to_f / @tile_total * 100).round(2)
          percent_pr  = (@processed.to_f  / @tile_total * 100).round(2)
          msg = format('[DL %05d/%05d — %5.1f%%]  [PROC %05d/%05d — %5.1f%%]',
                        @downloaded, @tile_total, percent_dl,
                        @processed,  @tile_total, percent_pr)
          @logger.info(msg)
        end
      end
    end
  end
end
