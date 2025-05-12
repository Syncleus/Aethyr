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

module Aethyr
  module Core
    module Util
      # WorldCoverGenerator orchestrates the download, cache management, and
      # incremental processing of ESA WorldCover raster tiles so that an
      # in-game representation of planet Earth can be constructed.  Download
      # and processing are pipelined: up to MAX_CONCURRENT_DOWNLOADS run in   
      # parallel while the main thread converts completed files into game      
      # entities.                                                              
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
                       logger: Logger.new($stdout))
          raise ArgumentError, 'Manager cannot be nil' unless manager

          @manager   = manager
          @logger    = logger
          @res       = resolution < 10 ? 10 : resolution
          @max_dl    = [max_concurrent_downloads, 1].max

          @download_queue  = Queue.new   # tile_code strings awaiting fetch
          @process_queue   = Queue.new   # local .tif paths awaiting raster-to-rooms

          @downloaded      = 0          # tiles fetched & cached this session
          @processed       = 0          # tiles converted into Aethyr rooms

          @tile_total      = nil        # lazy initialised once queue is populated
          @mutex           = Mutex.new  # protects @downloaded/@processed counters
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

          @logger.info("Tiles to download: #{@tile_total}. Starting #{@max_dl} download threads …")

          download_threads = spawn_download_pool

          # The main thread becomes the processing worker, turning finished
          # downloads into game objects while downloads continue in the
          # background.
          process_tiles_until_done(download_threads)
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
        # Processing stage                                                   #
        # ------------------------------------------------------------------- #

        # Continues until *all* tiles have been processed and the download
        # workers have exited.
        def process_tiles_until_done(download_threads)
          prev_row_room_goids = {}

          until done?(download_threads)
            tif_path = nil

            # Non-blocking pop so we can poll thread liveness once queue empty.
            begin
              tif_path = @process_queue.pop(true)
            rescue ThreadError
              tif_path = nil
            end

            if tif_path
              tile_code = File.basename(tif_path)[/N\d{2}[EW]\d{3}/]
              @logger.info("Processing #{tile_code} …")
              process_tile(tif_path, prev_row_room_goids)
              increment_process_counter
            else
              sleep 0.1 # back-off whilst waiting for more work
            end
          end
        end

        # Returns true when no download thread is alive and the process queue
        # has been drained.
        def done?(threads)
          threads_done = threads.none?(&:alive?)
          queue_empty   = @process_queue.empty?
          threads_done && queue_empty
        end

        # Converts a GeoTIFF into game objects. An Area is created per tile and
        # a grid of Room objects fills the Area. Each Room is linked to its
        # western and northern neighbours in order to build a contiguous, fully
        # navigable world graph.
        #
        # Because loading the entire 36000×36000 pixel raster into memory is
        # infeasible we stream scan-lines and operate in a single-pass manner.
        # The prev_row_room_goids hash carries GOIDs for the row immediately
        # above the one currently being generated so that vertical Exit objects
        # can be inserted without revisiting previous rows.
        def process_tile(tif_path, prev_row_room_goids)
          ds         = Gdal::Gdal.open(tif_path)
          band       = ds.get_raster_band(1)
          width      = ds.RasterXSize
          height     = ds.RasterYSize

          # ----------------------------------------------------------------
          # Per-tile progress tracking                                       
          # ----------------------------------------------------------------
          tile_code = File.basename(tif_path)[/N\d{2}[EW]\d{3}/]
          step_px   = @res / 10
          rows      = (height.to_f / step_px).ceil
          cols      = (width.to_f  / step_px).ceil
          cells_total = rows * cols
          cells_done  = 0

          # We emit at most 40 updates (2.5 % granularity) to strike a good
          # balance between feedback fidelity and log verbosity.
          updates_max           = 40
          update_interval_cells = [1, (cells_total / updates_max).floor].max

          # Helper lambda renders a fixed-width ASCII progress bar similar to
          # the global counters but scoped to a single tile.
          render_tile_bar = lambda do |percent|
            bar_width = 20
            filled    = (percent * bar_width / 100).round
            bar       = '=' * filled + ' ' * (bar_width - filled)
            format('[TILE %s] %6.2f%% |%s|', tile_code, percent, bar)
          end

          area_name  = "Area #{File.basename(tif_path, '.tif')}"
          area       = @manager.create_object(Aethyr::Core::Objects::Area, nil, nil, nil, :@name => area_name)

          # Helper for generating flavour text – memoised so repeated calls for
          # the same terrain symbol do not trigger new random selections.
          flavour_cache = {}

          # Pre-compute sample positions to avoid generating the same ranges
          # over and over inside the hot inner loop.
          step_px       = @res / 10
          sample_x      = (0...width).step(step_px).to_a

          # Iterate over raster scan-lines at the chosen stride. Reading an
          # entire scan-line in one GDAL call is *vastly* faster than
          #  performing a separate 1×1 window read per cell.
          (0...height).step(step_px).each do |y|
            current_row_goids = {}

            # Read the full row once – this is a contiguous `String` of bytes
            # (one byte per pixel) that we can index directly.
            row_data = band.read_raster(0, y, width, 1)

            sample_x.each do |x|
              code       = row_data.getbyte(x)
              terrain_sym = CODE_TO_TERRAIN[code] || :GRASSLAND
              terrain_const = ::Terrain.const_get(terrain_sym)

              name, desc = flavour_cache[terrain_sym] ||= [
                NAME_TEMPLATES[terrain_sym]&.sample || terrain_const.name.capitalize,
                DESCRIPTION_TEMPLATES[terrain_sym]&.sample || "An unremarkable #{terrain_const.room_text}."
              ]

              room = @manager.create_object(
                Aethyr::Core::Objects::Room,
                area,
                [x, y],
                nil,
                :@name => name,
                :@short_desc => desc
              )
              room.info.terrain.type = terrain_const

              current_row_goids[x] = room.goid

              # WEST/EAST linkage (left neighbour exists in same row)
              if (prev_gid = current_row_goids[x - (@res / 10)])
                link_rooms(prev_gid, room.goid, 'east', 'west')
              end

              # NORTH/SOUTH linkage (room above in previous row)
              if (north_gid = prev_row_room_goids[x])
                link_rooms(north_gid, room.goid, 'south', 'north')
              end

              # Record the very first room as spawn/start location.
              @start_room_goid ||= room.goid

              # -----------------------------------------------------------
              # Per-tile progress update                                   
              # -----------------------------------------------------------
              cells_done += 1
              if (cells_done % update_interval_cells).zero? || cells_done == cells_total
                percent = (cells_done.to_f / cells_total * 100)
                @logger.info(render_tile_bar.call(percent))
              end
            end

            # Finished one raster line.
            prev_row_room_goids.replace(current_row_goids)
          end

        ensure
          # The SWIG-generated Dataset wrapper does not expose an explicit
          # close/destroy method.  Releasing our reference allows Ruby's GC
          # to reclaim native resources deterministically once no Dataset
          # objects remain reachable.
          ds = nil
        end

        # Create bidirectional Exit objects between two rooms.
        def link_rooms(room_a_gid, room_b_gid, name_a_to_b, name_b_to_a)
          room_a = @manager.get_object(room_a_gid)
          room_b = @manager.get_object(room_b_gid)

          return if room_a.nil? || room_b.nil?

          @manager.create_object(
            Aethyr::Core::Objects::Exit,
            room_a,
            nil,
            room_b_gid,
            :@alt_names => [name_a_to_b]
          )

          @manager.create_object(
            Aethyr::Core::Objects::Exit,
            room_b,
            nil,
            room_a_gid,
            :@alt_names => [name_b_to_a]
          )
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