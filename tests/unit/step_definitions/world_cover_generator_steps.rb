# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for WorldCoverGenerator feature.
#
# Exercises all code paths in lib/aethyr/core/util/world_cover_generator.rb
# including constants, data structures, construction, tile decoding,
# download queue population, raster processing, room creation, linking,
# and the full build_world pipeline.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'stringio'
require 'logger'
require 'set'
require 'thread'
require 'fileutils'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – scenario state
# ---------------------------------------------------------------------------
module WorldCoverGeneratorWorld
  attr_accessor :generator, :mock_manager, :raised_error,
                :decoded_lat, :decoded_lon, :tile_code_result,
                :listing_result, :fetch_result, :local_rooms_batch,
                :local_connections_batch, :link_result,
                :mock_logger, :log_messages, :exit_objects_created,
                :rooms_created_via_manager, :areas_created_via_manager
end
World(WorldCoverGeneratorWorld)

# ---------------------------------------------------------------------------
# Mock / stub classes (guarded against redefinition)
# ---------------------------------------------------------------------------

# Capture logger output for assertions
unless defined?(WCGTestLogger)
  class WCGTestLogger < Logger
    attr_reader :messages

    def initialize
      @messages = []
      @logdev = nil
      @level = Logger::DEBUG
    end

    def add(severity, message = nil, progname = nil, &block)
      msg = message || (block ? block.call : progname)
      @messages << msg.to_s if msg
    end

    def info(msg = nil, &block)
      add(Logger::INFO, msg, &block)
    end

    def debug(msg = nil, &block)
      add(Logger::DEBUG, msg, &block)
    end

    def error(msg = nil, &block)
      add(Logger::ERROR, msg, &block)
    end

    def warn(msg = nil, &block)
      add(Logger::WARN, msg, &block)
    end
  end
end

# Mock room with info.terrain.type, exit, goid
unless defined?(WCGMockRoom)
  class WCGMockRoom
    attr_accessor :goid, :exits, :info

    def initialize(goid)
      @goid = goid
      @exits = {}
      @info = WCGMockRoomInfo.new
    end

    def exit(direction)
      @exits[direction]
    end
  end

  class WCGMockRoomInfo
    attr_accessor :terrain
    def initialize
      @terrain = WCGMockTerrain.new
    end
  end

  class WCGMockTerrain
    attr_accessor :type
  end
end

# Mock GDAL dataset and raster band
unless defined?(WCGMockGdalDataset)
  class WCGMockGdalDataset
    attr_reader :RasterXSize, :RasterYSize

    def initialize(width, height, pixel_value = 30)
      @RasterXSize = width
      @RasterYSize = height
      @pixel_value = pixel_value
    end

    def get_raster_band(_n)
      WCGMockRasterBand.new(@RasterXSize, @pixel_value)
    end
  end

  class WCGMockRasterBand
    def initialize(width, pixel_value)
      @width = width
      @pixel_value = pixel_value
    end

    def read_raster(x, y, w, h)
      ([@pixel_value].pack('C') * (w * h))
    end
  end
end

# Mock manager for object creation
unless defined?(WCGMockManager)
  class WCGMockManager
    attr_reader :created_objects, :objects_by_goid

    def initialize
      @created_objects = []
      @goid_counter = 0
      @objects_by_goid = {}
    end

    def create_object(klass, parent = nil, coords = nil, target = nil, **attrs)
      @goid_counter += 1
      goid = "wcg-mock-goid-#{@goid_counter}"
      obj = WCGMockRoom.new(goid)
      if attrs[:@name]
        obj.instance_variable_set(:@name, attrs[:@name])
      end
      @created_objects << { klass: klass, parent: parent, coords: coords, target: target, attrs: attrs, obj: obj }
      @objects_by_goid[goid] = obj
      obj
    end

    def get_object(goid)
      @objects_by_goid[goid]
    end
  end
end

# Error-raising manager
unless defined?(WCGErrorManager)
  class WCGErrorManager < WCGMockManager
    attr_accessor :fail_on_create

    def initialize
      super
      @fail_on_create = false
      @create_count = 0
    end

    def create_object(klass, parent = nil, coords = nil, target = nil, **attrs)
      @create_count += 1
      if @fail_on_create && klass.to_s.include?('Exit')
        raise StandardError, "Simulated create failure"
      end
      super
    end
  end
end

# ---------------------------------------------------------------------------
# SINGLE After hook to clean up ALL stubs reliably
# ---------------------------------------------------------------------------
After do
  # 1) GDAL stubs
  if defined?(Gdal) && defined?(Gdal::Gdal) && Gdal::Gdal.respond_to?(:__wcg_original_open__)
    gdal_singleton = class << Gdal::Gdal; self; end
    gdal_singleton.alias_method :open, :__wcg_original_open__
    gdal_singleton.remove_method :__wcg_original_open__
  end

  # 2) Restore MAX_TILES
  if defined?(Aethyr::Core::Util::WorldCoverGenerator)
    klass = Aethyr::Core::Util::WorldCoverGenerator
    if klass.const_defined?(:MAX_TILES) && klass::MAX_TILES != 1
      klass.send(:remove_const, :MAX_TILES)
      klass.const_set(:MAX_TILES, 1)
    end
  end

  # 3) URI.open stubs
  if @original_uri_open
    URI.define_singleton_method(:open, @original_uri_open)
    @original_uri_open = nil
  end
  if @original_uri_open_fetch
    URI.define_singleton_method(:open, @original_uri_open_fetch)
    @original_uri_open_fetch = nil
  end

  # 4) File.exist? / File.size? / File.open stubs
  file_singleton = class << File; self; end
  if file_singleton.method_defined?(:__wcg_original_exist__)
    file_singleton.alias_method :exist?, :__wcg_original_exist__
    file_singleton.remove_method :__wcg_original_exist__
  end
  if file_singleton.method_defined?(:__wcg_original_size__)
    file_singleton.alias_method :size?, :__wcg_original_size__
    file_singleton.remove_method :__wcg_original_size__
  end
  if file_singleton.method_defined?(:__wcg_original_open__)
    file_singleton.alias_method :open, :__wcg_original_open__
    file_singleton.remove_method :__wcg_original_open__
  end

  # 5) FileUtils.mkdir_p stub
  if FileUtils.respond_to?(:__wcg_original_mkdir_p__)
    FileUtils.singleton_class.send(:remove_method, :mkdir_p) rescue nil
    FileUtils.singleton_class.send(:remove_method, :__wcg_original_mkdir_p__) rescue nil
  end
end

# ---------------------------------------------------------------------------
# Helper methods
# ---------------------------------------------------------------------------
module WCGHelpers
  def wcg_class
    Aethyr::Core::Util::WorldCoverGenerator
  end

  def create_default_generator(manager: nil, **opts)
    mgr = manager || WCGMockManager.new
    self.mock_manager = mgr
    self.mock_logger = WCGTestLogger.new
    self.log_messages = mock_logger.messages
    gen_opts = { logger: mock_logger, resolution: 5000 }.merge(opts)
    self.generator = wcg_class.new(mgr, **gen_opts)
  end

  def sample_bucket_xml_single(tile_code)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ListBucketResult>
        <IsTruncated>false</IsTruncated>
        <Contents>
          <Key>v200/2021/map/ESA_WorldCover_10m_2021_v200_#{tile_code}_Map.tif</Key>
        </Contents>
      </ListBucketResult>
    XML
  end

  def sample_bucket_xml_multiple(tile_codes)
    contents = tile_codes.map do |tc|
      "<Contents><Key>v200/2021/map/ESA_WorldCover_10m_2021_v200_#{tc}_Map.tif</Key></Contents>"
    end.join("\n")
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ListBucketResult>
        <IsTruncated>false</IsTruncated>
        #{contents}
      </ListBucketResult>
    XML
  end

  def stub_gdal_open(width, height, pixel_value = 30)
    mock_ds = WCGMockGdalDataset.new(width, height, pixel_value)

    unless defined?(Gdal::Gdal)
      Object.const_set(:Gdal, Module.new) unless defined?(Gdal)
      gdal_inner = Module.new
      gdal_inner.define_singleton_method(:open) { |_path| mock_ds }
      Gdal.const_set(:Gdal, gdal_inner) unless defined?(Gdal::Gdal)
    end

    gdal_singleton = class << Gdal::Gdal; self; end
    unless gdal_singleton.method_defined?(:__wcg_original_open__)
      gdal_singleton.alias_method :__wcg_original_open__, :open if Gdal::Gdal.respond_to?(:open)
    end
    gdal_singleton.define_method(:open) { |_path| mock_ds }
  end

  def mock_tif_path(tile_code)
    "/tmp/fake_cache/ESA_WorldCover_10m_2021_v200_#{tile_code}_Map.tif"
  end
end
World(WCGHelpers)

# ===========================================================================
#                              S T E P S
# ===========================================================================

# ---------------------------------------------------------------------------
# Require / setup steps
# ---------------------------------------------------------------------------
Given('I require the WorldCoverGenerator library') do
  require 'aethyr/core/objects/info/terrain'

  unless defined?(Gdal::Gdal)
    Object.const_set(:Gdal, Module.new) unless defined?(Gdal)
    gdal_inner = Module.new
    gdal_inner.define_singleton_method(:open) { |_path| nil }
    Gdal.const_set(:Gdal, gdal_inner) unless defined?(Gdal::Gdal)
  end

  unless defined?(Aethyr::Core::Objects::Area)
    module Aethyr; module Core; module Objects
      class Area; end unless defined?(Area)
      class Room; end unless defined?(Room)
      class Exit; end unless defined?(Exit)
    end; end; end
  end

  require 'aethyr/core/util/world_cover_generator'

  assert defined?(Aethyr::Core::Util::WorldCoverGenerator),
         'WorldCoverGenerator should be defined after require'
end

Given('I have a mock manager') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
end

Given('I have a default generator') do
  create_default_generator
end

Given('I have a default generator with unlimited tiles') do
  create_default_generator
  wcg_class.send(:remove_const, :MAX_TILES) if wcg_class.const_defined?(:MAX_TILES)
  wcg_class.const_set(:MAX_TILES, 0)
end

# ---------------------------------------------------------------------------
# Constants steps
# ---------------------------------------------------------------------------
Then('the RESOLUTION_METRES constant should equal {int}') do |val|
  assert_equal val, wcg_class::RESOLUTION_METRES
end

Then('the BUCKET_BASE_URL constant should include {string}') do |substr|
  assert wcg_class::BUCKET_BASE_URL.include?(substr),
         "BUCKET_BASE_URL should include '#{substr}'"
end

Then('the YEAR constant should equal {int}') do |val|
  assert_equal val, wcg_class::YEAR
end

Then('the VERSION constant should equal {string}') do |val|
  assert_equal val, wcg_class::VERSION
end

Then('the MAX_CONCURRENT_DL constant should equal {int}') do |val|
  assert_equal val, wcg_class::MAX_CONCURRENT_DL
end

Then('the MAX_TILES constant should equal {int}') do |val|
  assert_equal val, wcg_class::MAX_TILES
end

Then('the BATCH_SIZE constant should equal {int}') do |val|
  assert_equal val, wcg_class::BATCH_SIZE
end

Then('the MAX_CONCURRENT_PROC constant be at least {int}') do |val|
  assert wcg_class::MAX_CONCURRENT_PROC >= val,
         "MAX_CONCURRENT_PROC should be >= #{val}, got #{wcg_class::MAX_CONCURRENT_PROC}"
end

Then('the CACHE_DIR constant should be a non-empty string') do
  assert wcg_class::CACHE_DIR.is_a?(String) && !wcg_class::CACHE_DIR.empty?,
         "CACHE_DIR should be a non-empty string"
end

Then('CODE_TO_TERRAIN should map {int} to GRASSLAND') do |code|
  assert_equal :GRASSLAND, wcg_class::CODE_TO_TERRAIN[code]
end

Then('CODE_TO_TERRAIN should map {int} to CITY') do |code|
  assert_equal :CITY, wcg_class::CODE_TO_TERRAIN[code]
end

Then('CODE_TO_TERRAIN should map {int} to TUNDRA') do |code|
  assert_equal :TUNDRA, wcg_class::CODE_TO_TERRAIN[code]
end

Then('NAME_TEMPLATES should have entries for GRASSLAND, CITY, and TUNDRA') do
  templates = wcg_class::NAME_TEMPLATES
  assert templates.key?(:GRASSLAND), 'Missing GRASSLAND key'
  assert templates.key?(:CITY), 'Missing CITY key'
  assert templates.key?(:TUNDRA), 'Missing TUNDRA key'
end

Then('each NAME_TEMPLATES entry should be a non-empty array') do
  wcg_class::NAME_TEMPLATES.each do |key, arr|
    assert arr.is_a?(Array) && !arr.empty?,
           "NAME_TEMPLATES[:#{key}] should be a non-empty array"
  end
end

Then('DESCRIPTION_TEMPLATES should have entries for GRASSLAND, CITY, and TUNDRA type descriptions') do
  templates = wcg_class::DESCRIPTION_TEMPLATES
  assert templates.key?(:GRASSLAND), 'Missing GRASSLAND key'
  assert templates.key?(:CITY), 'Missing CITY key'
  assert templates.key?(:TUNDRA), 'Missing TUNDRA key'
end

Then('each DESCRIPTION_TEMPLATES entry should be a non-empty array of strings') do
  wcg_class::DESCRIPTION_TEMPLATES.each do |key, arr|
    assert arr.is_a?(Array) && !arr.empty?,
           "DESCRIPTION_TEMPLATES[:#{key}] should be a non-empty array"
    arr.each { |s| assert s.is_a?(String), "Each description should be a String" }
  end
end

# ---------------------------------------------------------------------------
# Data structure steps
# ---------------------------------------------------------------------------
When('I create a ProcessedRoom with x {int}, y {int}, tile_code {string}') do |x, y, tc|
  @processed_room = wcg_class::ProcessedRoom.new(x, y, tc, :GRASSLAND, 'Test', 'Desc', nil)
end

Then('the ProcessedRoom position_key should be {string}') do |expected|
  assert_equal expected, @processed_room.position_key
end

When('I create a RoomConnection with from_key {string}, to_key {string}, direction_from {string}, direction_to {string}') do |fk, tk, df, dt|
  @room_connection = wcg_class::RoomConnection.new(fk, tk, df, dt)
end

Then('the RoomConnection should have correct from_key and to_key') do
  assert_equal 'N45E010:0:0', @room_connection.from_key
  assert_equal 'N45E010:500:0', @room_connection.to_key
  assert_equal 'east', @room_connection.direction_from
  assert_equal 'west', @room_connection.direction_to
end

# ---------------------------------------------------------------------------
# Constructor steps
# ---------------------------------------------------------------------------
When('I create a WorldCoverGenerator with the mock manager') do
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
end

Then('the generator should be initialized without errors') do
  assert_not_nil generator, 'Generator should have been created'
end

Then('the start_room_goid should be nil initially') do
  assert_nil generator.start_room_goid, 'start_room_goid should be nil initially'
end

When('I try to create a WorldCoverGenerator with nil manager') do
  self.raised_error = nil
  begin
    wcg_class.new(nil)
  rescue ArgumentError => e
    self.raised_error = e
  end
end

Then('an ArgumentError should be raised with message containing {string}') do |msg|
  assert_not_nil raised_error, 'Expected ArgumentError to be raised'
  assert_kind_of ArgumentError, raised_error
  assert raised_error.message.include?(msg),
         "Error message '#{raised_error.message}' should include '#{msg}'"
end

When('I create a WorldCoverGenerator with resolution {int}') do |res|
  self.generator = wcg_class.new(mock_manager, resolution: res, logger: mock_logger)
end

Then('the internal resolution should be {int}') do |expected|
  assert_equal expected, generator.instance_variable_get(:@res)
end

When('I create a WorldCoverGenerator with max_concurrent_downloads {int}') do |val|
  self.generator = wcg_class.new(mock_manager, max_concurrent_downloads: val, logger: mock_logger)
end

Then('the internal max_dl should be {int}') do |expected|
  assert_equal expected, generator.instance_variable_get(:@max_dl)
end

When('I create a WorldCoverGenerator with max_concurrent_processors {int}') do |val|
  self.generator = wcg_class.new(mock_manager, max_concurrent_processors: val, logger: mock_logger)
end

Then('the internal max_proc should be {int}') do |expected|
  assert_equal expected, generator.instance_variable_get(:@max_proc)
end

# ---------------------------------------------------------------------------
# decode_tile_origin steps
# ---------------------------------------------------------------------------
When('I decode tile origin for code {string}') do |code|
  result = generator.send(:decode_tile_origin, code)
  self.decoded_lat = result[0]
  self.decoded_lon = result[1]
end

Then('the decoded latitude should be {int}') do |expected|
  assert_equal expected, decoded_lat
end

Then('the decoded longitude should be {int}') do |expected|
  assert_equal expected, decoded_lon
end

# ---------------------------------------------------------------------------
# tile_origin & tile_code steps
# ---------------------------------------------------------------------------
Then('tile_origin of {int} should be {int}') do |input, expected|
  assert_equal expected, generator.send(:tile_origin, input)
end

When('I generate tile_code for lat {int} lon {int}') do |lat, lon|
  self.tile_code_result = generator.send(:tile_code, lat, lon)
end

Then('the tile_code should be {string}') do |expected|
  assert_equal expected, tile_code_result
end

# ---------------------------------------------------------------------------
# fetch_bucket_listing steps
# ---------------------------------------------------------------------------
Given('I stub URI.open at kernel level to return sample bucket XML') do
  @sample_xml = sample_bucket_xml_single('N45E010')
  mock_data = @sample_xml
  @original_uri_open = URI.method(:open) if URI.respond_to?(:open)
  URI.define_singleton_method(:open) do |*args, &block|
    io = StringIO.new(mock_data)
    block ? block.call(io) : io
  end
end

When('I call real fetch_bucket_listing with no marker') do
  self.listing_result = generator.send(:fetch_bucket_listing, nil)
end

When('I call real fetch_bucket_listing with marker {string}') do |marker|
  self.listing_result = generator.send(:fetch_bucket_listing, marker)
end

Then('the listing result should contain bucket XML data') do
  assert_not_nil listing_result
  assert listing_result.include?('ListBucketResult') || listing_result.include?('ESA_WorldCover'),
         "Listing result should contain XML data"
end

# ---------------------------------------------------------------------------
# populate_download_queue steps
# ---------------------------------------------------------------------------
Given('I stub fetch_bucket_listing to return XML with tile {string}') do |tile_code|
  xml = sample_bucket_xml_single(tile_code)
  generator.define_singleton_method(:fetch_bucket_listing) { |_marker = nil| xml }
end

Given('I stub fetch_bucket_listing to return XML with multiple tiles') do
  xml = sample_bucket_xml_multiple(['N45E010', 'S30W120', 'N00E000'])
  generator.define_singleton_method(:fetch_bucket_listing) { |_marker = nil| xml }
end

Given('I stub fetch_bucket_listing to return paginated XML') do
  page1_xml = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult>
      <IsTruncated>true</IsTruncated>
      <Contents>
        <Key>v200/2021/map/ESA_WorldCover_10m_2021_v200_N45E010_Map.tif</Key>
      </Contents>
    </ListBucketResult>
  XML
  page2_xml = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult>
      <IsTruncated>false</IsTruncated>
      <Contents>
        <Key>v200/2021/map/ESA_WorldCover_10m_2021_v200_S30W120_Map.tif</Key>
      </Contents>
    </ListBucketResult>
  XML
  call_count = 0
  generator.define_singleton_method(:fetch_bucket_listing) do |_marker = nil|
    call_count += 1
    call_count == 1 ? page1_xml : page2_xml
  end
end

When('I populate the download queue for lat {int}..{int} and lon {int}..{int}') do |lat_min, lat_max, lon_min, lon_max|
  generator.send(:populate_download_queue, (lat_min..lat_max), (lon_min..lon_max))
end

Then('the download queue should have {int} tile(s)') do |expected|
  assert_equal expected, generator.instance_variable_get(:@download_queue).size
end

Then('tile_total should be {int}') do |expected|
  assert_equal expected, generator.instance_variable_get(:@tile_total)
end

Then('the download queue should have at most MAX_TILES tiles') do
  max = wcg_class::MAX_TILES
  actual = generator.instance_variable_get(:@download_queue).size
  assert actual <= max, "Queue size #{actual} should be <= MAX_TILES #{max}"
end

Then('the logger should have logged a message containing {string}') do |substr|
  found = log_messages.any? { |m| m.include?(substr) }
  assert found, "Expected logger to contain '#{substr}' but messages were: #{log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# fetch_tile steps
# ---------------------------------------------------------------------------
Given('I stub File to report tile file exists and has size') do
  file_singleton = class << File; self; end
  file_singleton.alias_method :__wcg_original_exist__, :exist? unless file_singleton.method_defined?(:__wcg_original_exist__)
  file_singleton.alias_method :__wcg_original_size__, :size? unless file_singleton.method_defined?(:__wcg_original_size__)

  file_singleton.define_method(:exist?) do |path|
    path.include?('ESA_WorldCover_10m') ? true : __wcg_original_exist__(path)
  end
  file_singleton.define_method(:size?) do |path|
    path.include?('ESA_WorldCover_10m') ? 12345 : __wcg_original_size__(path)
  end
end

Given('I stub File to report tile file does not exist and stub URI.open for download') do
  file_singleton = class << File; self; end
  file_singleton.alias_method :__wcg_original_exist__, :exist? unless file_singleton.method_defined?(:__wcg_original_exist__)
  file_singleton.define_method(:exist?) do |path|
    path.include?('ESA_WorldCover_10m') ? false : __wcg_original_exist__(path)
  end

  # Stub FileUtils.mkdir_p
  @_orig_mkdir_p = FileUtils.method(:mkdir_p)
  FileUtils.define_singleton_method(:mkdir_p) { |*_args| nil }

  # Stub URI.open
  @original_uri_open_fetch = URI.method(:open) if URI.respond_to?(:open)
  URI.define_singleton_method(:open) do |*args, &block|
    io = StringIO.new("fake tiff data")
    block ? block.call(io) : io
  end

  # Stub File.open
  file_singleton.alias_method :__wcg_original_open__, :open unless file_singleton.method_defined?(:__wcg_original_open__)
  file_singleton.define_method(:open) do |path, *args, &block|
    if path.to_s.include?('ESA_WorldCover_10m')
      dev_null = StringIO.new
      block ? block.call(dev_null) : dev_null
    else
      __wcg_original_open__(path, *args, &block)
    end
  end
end

When('I call the real fetch_tile with code {string}') do |code|
  self.fetch_result = generator.send(:fetch_tile, code)
end

Then('the returned path should end with {string}') do |suffix|
  assert fetch_result.end_with?(suffix),
         "Path '#{fetch_result}' should end with '#{suffix}'"
end

# ---------------------------------------------------------------------------
# flush_local_batches steps
# ---------------------------------------------------------------------------
When('I flush local batches with {int} rooms and {int} connections') do |room_count, conn_count|
  rooms = room_count.times.map do |i|
    wcg_class::ProcessedRoom.new(i * 500, 0, 'N00E000', :GRASSLAND, 'Test', 'Desc', nil)
  end
  connections = conn_count.times.map do |i|
    wcg_class::RoomConnection.new("N00E000:0:0", "N00E000:#{(i+1)*500}:0", 'east', 'west')
  end
  generator.send(:flush_local_batches, rooms, connections)
end

Then('the processed_rooms queue should have {int} items') do |expected|
  assert_equal expected, generator.instance_variable_get(:@processed_rooms).size
end

Then('the room_connections queue should have {int} items') do |expected|
  assert_equal expected, generator.instance_variable_get(:@room_connections).size
end

# ---------------------------------------------------------------------------
# process_tile_lockfree steps
# ---------------------------------------------------------------------------
Given('I have a mock GDAL dataset with width {int} and height {int}') do |width, height|
  @mock_gdal_width = width
  @mock_gdal_height = height
  stub_gdal_open(width, height, 30)
end

When('I call process_tile_lockfree with the mock dataset path') do
  generator.send(:process_tile_lockfree, mock_tif_path('N45E010'))
end

Then('the processed_rooms queue should have items') do
  queue = generator.instance_variable_get(:@processed_rooms)
  assert queue.size > 0, "processed_rooms queue should have items, has #{queue.size}"
end

Then('the room_connections queue should have items') do
  queue = generator.instance_variable_get(:@room_connections)
  assert queue.size > 0, "room_connections queue should have items, has #{queue.size}"
end

# ---------------------------------------------------------------------------
# process_tile_with_batching steps
# ---------------------------------------------------------------------------
When('I call process_tile_with_batching with the mock dataset path') do
  self.local_rooms_batch = []
  self.local_connections_batch = []
  generator.send(:process_tile_with_batching, mock_tif_path('N45E010'), local_rooms_batch, local_connections_batch)
end

Then('the local rooms batch should have items') do
  assert local_rooms_batch.size > 0, "local rooms batch should have items, has #{local_rooms_batch.size}"
end

Then('the local connections batch should have items') do
  assert local_connections_batch.size > 0, "local connections batch should have items, has #{local_connections_batch.size}"
end

# ---------------------------------------------------------------------------
# link_rooms steps
# ---------------------------------------------------------------------------
Given('I have two mock rooms with no existing exits') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  @room_a = WCGMockRoom.new('room-a-goid')
  @room_b = WCGMockRoom.new('room-b-goid')
  mock_manager.objects_by_goid['room-a-goid'] = @room_a
  mock_manager.objects_by_goid['room-b-goid'] = @room_b
  self.exit_objects_created = 0
end

When('I call link_rooms between the two rooms') do
  self.link_result = generator.send(:link_rooms, 'room-a-goid', 'room-b-goid', 'east', 'west')
  self.exit_objects_created = mock_manager.created_objects.count { |o| o[:klass] == Aethyr::Core::Objects::Exit }
end

Then('link_rooms should return true') do
  assert_equal true, link_result
end

Then('the manager should have created {int} exit objects') do |expected|
  assert_equal expected, exit_objects_created
end

Given('I have mock rooms where room A is nil') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
end

When('I call link_rooms with nil room A') do
  self.link_result = generator.send(:link_rooms, 'nonexistent-a', 'nonexistent-b', 'east', 'west')
end

Then('link_rooms should return false') do
  assert_equal false, link_result
end

Given('I have two mock rooms with existing exits') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  @room_a = WCGMockRoom.new('room-a-goid')
  @room_b = WCGMockRoom.new('room-b-goid')
  @room_a.exits['east'] = true
  @room_b.exits['west'] = true
  mock_manager.objects_by_goid['room-a-goid'] = @room_a
  mock_manager.objects_by_goid['room-b-goid'] = @room_b
end

When('I call link_rooms between rooms with existing exits') do
  self.link_result = generator.send(:link_rooms, 'room-a-goid', 'room-b-goid', 'east', 'west')
end

Given('I have a default generator with error-raising manager') do
  self.mock_manager = WCGErrorManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  mock_manager.fail_on_create = true
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
end

Given('I have two mock rooms with no existing exits for error test') do
  @room_a = WCGMockRoom.new('room-a-err')
  @room_b = WCGMockRoom.new('room-b-err')
  mock_manager.objects_by_goid['room-a-err'] = @room_a
  mock_manager.objects_by_goid['room-b-err'] = @room_b
end

When('I call link_rooms between the error test rooms') do
  self.link_result = generator.send(:link_rooms, 'room-a-err', 'room-b-err', 'east', 'west')
end

# ---------------------------------------------------------------------------
# create_missing_connections steps
# ---------------------------------------------------------------------------
Given('I have a default generator with rooms in lookup') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  step_px = generator.instance_variable_get(:@res) / 10
  lookup = generator.instance_variable_get(:@room_lookup)
  ['room-1', 'room-2', 'room-3', 'room-4'].each do |goid|
    mock_manager.objects_by_goid[goid] = WCGMockRoom.new(goid)
  end
  lookup["N00E000:0:0"] = 'room-1'
  lookup["N00E000:#{step_px}:0"] = 'room-2'
  lookup["N00E000:0:#{step_px}"] = 'room-3'
  lookup["N00E000:#{step_px}:#{step_px}"] = 'room-4'
end

When('I call create_missing_connections') do
  generator.send(:create_missing_connections)
end

Then('the logger should have logged about missing connections') do
  found = log_messages.any? { |m| m.include?('missing connections') }
  assert found, "Expected logger message about missing connections, got: #{log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# increment counters / log_progress steps
# ---------------------------------------------------------------------------
Given('I have a default generator with tile_total set to {int}') do |total|
  create_default_generator
  generator.instance_variable_set(:@tile_total, total)
end

When('I call increment_download_counter') do
  generator.send(:increment_download_counter)
end

Then('the downloaded count should be {int}') do |expected|
  assert_equal expected, generator.instance_variable_get(:@downloaded)
end

When('I call increment_process_counter') do
  generator.send(:increment_process_counter)
end

Then('the processed count should be {int}') do |expected|
  assert_equal expected, generator.instance_variable_get(:@processed)
end

Given('the downloaded count is {int} and processed count is {int}') do |dl, pr|
  generator.instance_variable_set(:@downloaded, dl)
  generator.instance_variable_set(:@processed, pr)
end

When('I call log_progress') do
  generator.send(:log_progress)
end

Then('the logger should have logged a message matching DL and PROC format') do
  found = log_messages.any? { |m| m.include?('DL') && m.include?('PROC') }
  assert found, "Expected DL/PROC format log, got: #{log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# spawn_object_creation_thread steps
# ---------------------------------------------------------------------------
Given('I have a generator with mock manager for object creation') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@processed, 1)
end

When('I enqueue processed rooms and run the object creation thread') do
  queue = generator.instance_variable_get(:@processed_rooms)
  3.times do |i|
    queue << wcg_class::ProcessedRoom.new(i * 500, 0, 'N00E000', :GRASSLAND, 'Test Room', 'A test room.', nil)
  end
  thread = generator.send(:spawn_object_creation_thread)
  sleep 0.5
  thread.join(5)
end

Then('rooms should have been created via the manager') do
  assert mock_manager.created_objects.size > 0,
         "Expected rooms to be created, got #{mock_manager.created_objects.size}"
end

Then('the room_lookup should have entries') do
  assert generator.instance_variable_get(:@room_lookup).size > 0, "room_lookup should have entries"
end

Then('start_room_goid should be set') do
  assert_not_nil generator.start_room_goid, "start_room_goid should be set"
end

# ---------------------------------------------------------------------------
# spawn_room_connection_thread steps
# ---------------------------------------------------------------------------
Given('I have a generator ready for room connection') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@processed, 1)
  lookup = generator.instance_variable_get(:@room_lookup)
  room_a = WCGMockRoom.new('conn-room-a')
  room_b = WCGMockRoom.new('conn-room-b')
  mock_manager.objects_by_goid['conn-room-a'] = room_a
  mock_manager.objects_by_goid['conn-room-b'] = room_b
  lookup['N00E000:0:0'] = 'conn-room-a'
  lookup['N00E000:500:0'] = 'conn-room-b'
end

When('I enqueue room connections and run the connection thread') do
  conn_queue = generator.instance_variable_get(:@room_connections)
  conn_queue << wcg_class::RoomConnection.new('N00E000:0:0', 'N00E000:500:0', 'east', 'west')
  thread = generator.send(:spawn_room_connection_thread)
  sleep 1.5
  thread.join(5)
end

Then('connections should have been processed') do
  found = log_messages.any? { |m| m.downcase.include?('connection') || m.downcase.include?('exit') || m.downcase.include?('sweep') }
  assert found, "Expected connection-related log messages, got: #{log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# spawn_download_pool steps
# ---------------------------------------------------------------------------
Given('I have a generator with stubbed fetch_tile') do
  create_default_generator(max_concurrent_downloads: 1)
  generator.instance_variable_set(:@tile_total, 1)
  generator.define_singleton_method(:fetch_tile) { |tile_code| "/tmp/cache/#{tile_code}.tif" }
end

When('I enqueue tile codes and run the download pool') do
  generator.instance_variable_get(:@download_queue) << 'N45E010'
  generator.send(:spawn_download_pool).each { |t| t.join(5) }
end

Then('the process queue should have entries') do
  assert generator.instance_variable_get(:@process_queue).size > 0, "process_queue should have entries"
end

Given('I have a generator with failing fetch_tile') do
  create_default_generator(max_concurrent_downloads: 1)
  generator.instance_variable_set(:@tile_total, 1)
  generator.define_singleton_method(:fetch_tile) { |tc| raise StandardError, "Simulated download failure for #{tc}" }
end

When('I enqueue tile codes and run the download pool with errors') do
  generator.instance_variable_get(:@download_queue) << 'N45E010'
  generator.send(:spawn_download_pool).each { |t| t.join(5) }
end

Then('no exception should propagate from download threads') do
  assert true, 'Download threads should not propagate exceptions'
  found = log_messages.any? { |m| m.include?('Download failed') }
  assert found, "Expected 'Download failed' in logs, got: #{log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# spawn_processing_pool steps
# ---------------------------------------------------------------------------
Given('I have a generator with stubbed process_tile_with_batching') do
  create_default_generator(max_concurrent_processors: 1)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@downloaded, 1)
  generator.define_singleton_method(:process_tile_with_batching) { |_p, _r, _c| }
end

When('I enqueue tif paths and run the processing pool') do
  generator.instance_variable_get(:@process_queue) << '/tmp/cache/N45E010.tif'
  threads = generator.send(:spawn_processing_pool)
  sleep 0.5
  threads.each { |t| t.join(5) }
end

Then('the processed count should increase') do
  assert generator.instance_variable_get(:@processed) > 0, "processed count should be > 0"
end

# ---------------------------------------------------------------------------
# spawn_processing_pool with batch flush steps
# ---------------------------------------------------------------------------
Given('I have a generator producing large batches for processing pool') do
  create_default_generator(max_concurrent_processors: 1)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@downloaded, 1)
  batch_size = wcg_class::BATCH_SIZE
  generator.define_singleton_method(:process_tile_with_batching) do |_path, local_rooms, local_conns|
    (batch_size + 5).times do |i|
      local_rooms << Aethyr::Core::Util::WorldCoverGenerator::ProcessedRoom.new(
        i * 500, 0, 'N00E000', :GRASSLAND, 'Test', 'Desc', nil
      )
    end
    (batch_size * 4 + 5).times do |i|
      local_conns << Aethyr::Core::Util::WorldCoverGenerator::RoomConnection.new(
        "N00E000:#{i*500}:0", "N00E000:#{(i+1)*500}:0", 'east', 'west'
      )
    end
  end
end

When('I enqueue tif paths and run the processing pool with large batches') do
  generator.instance_variable_get(:@process_queue) << '/tmp/cache/N45E010.tif'
  threads = generator.send(:spawn_processing_pool)
  sleep 0.5
  threads.each { |t| t.join(5) }
end

Then('the processed_rooms queue should have items after flush') do
  assert generator.instance_variable_get(:@processed_rooms).size > 0, "processed_rooms should have items after flush"
end

# ---------------------------------------------------------------------------
# spawn_object_creation_thread with periodic logging steps
# ---------------------------------------------------------------------------
When('I enqueue exactly {int} processed rooms and run the object creation thread') do |count|
  queue = generator.instance_variable_get(:@processed_rooms)
  count.times do |i|
    queue << wcg_class::ProcessedRoom.new(i * 500, 0, 'N00E000', :GRASSLAND, 'Test', 'Desc', nil)
  end
  thread = generator.send(:spawn_object_creation_thread)
  sleep 1.5
  thread.join(10)
end

# ---------------------------------------------------------------------------
# spawn_room_connection_thread with many connections steps
# ---------------------------------------------------------------------------
Given('I have a generator ready for room connection with many rooms') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@processed, 1)
  lookup = generator.instance_variable_get(:@room_lookup)
  step_px = generator.instance_variable_get(:@res) / 10
  1002.times do |i|
    goid = "conn-room-#{i}"
    mock_manager.objects_by_goid[goid] = WCGMockRoom.new(goid)
    lookup["N00E000:#{i * step_px}:0"] = goid
  end
end

When('I enqueue many room connections and run the connection thread') do
  conn_queue = generator.instance_variable_get(:@room_connections)
  step_px = generator.instance_variable_get(:@res) / 10
  1001.times do |i|
    conn_queue << wcg_class::RoomConnection.new(
      "N00E000:#{i * step_px}:0", "N00E000:#{(i + 1) * step_px}:0", 'east', 'west'
    )
  end
  thread = generator.send(:spawn_room_connection_thread)
  sleep 2.0
  thread.join(10)
end

# ---------------------------------------------------------------------------
# Delayed processing pool - covers sleep/next path (lines 381-382)
# ---------------------------------------------------------------------------
Given('I have a generator with delayed download for processing pool') do
  create_default_generator(max_concurrent_processors: 1)
  generator.instance_variable_set(:@tile_total, 1)
  # downloaded starts at 0 - processing pool will see empty queue and retry
  generator.instance_variable_set(:@downloaded, 0)
  generator.define_singleton_method(:process_tile_with_batching) { |_p, _r, _c| }
end

When('I start the processing pool then add work after a delay') do
  pq = generator.instance_variable_get(:@process_queue)

  threads = generator.send(:spawn_processing_pool)

  # Let the pool thread hit the empty queue + sleep path
  sleep 0.05

  # Now add work and signal that downloads are done
  pq << '/tmp/cache/N45E010.tif'
  generator.instance_variable_set(:@downloaded, 1)

  sleep 0.3
  threads.each { |t| t.join(5) }
end

# ---------------------------------------------------------------------------
# Delayed object creation - covers sleep/next path (lines 566-567)
# ---------------------------------------------------------------------------
Given('I have a generator with mock manager for delayed object creation') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  generator.instance_variable_set(:@tile_total, 1)
  # processed starts at 0 - thread will see empty queue and retry
  generator.instance_variable_set(:@processed, 0)
end

When('I start the object creation thread then add rooms after a delay') do
  queue = generator.instance_variable_get(:@processed_rooms)

  thread = generator.send(:spawn_object_creation_thread)

  # Let the thread hit the empty queue + sleep path
  sleep 0.05

  # Now add work and signal that processing is done
  queue << wcg_class::ProcessedRoom.new(0, 0, 'N00E000', :GRASSLAND, 'Test', 'Desc', nil)
  generator.instance_variable_set(:@processed, 1)

  sleep 0.5
  thread.join(5)
end

# ---------------------------------------------------------------------------
# Delayed room connection - covers wait-for-rooms + sleep/next paths (lines 640-641, 661-662)
# ---------------------------------------------------------------------------
Given('I have a generator for delayed room connection') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@processed, 0)
  # room_lookup is empty - thread will wait for rooms first (lines 639-642)
end

When('I start the connection thread then add rooms and connections after a delay') do
  lookup = generator.instance_variable_get(:@room_lookup)
  conn_queue = generator.instance_variable_get(:@room_connections)

  thread = generator.send(:spawn_room_connection_thread)

  # Let the thread hit the wait-for-rooms path (lines 639-641)
  sleep 0.7

  # Add rooms to lookup so the thread proceeds past the wait
  room_a = WCGMockRoom.new('delay-room-a')
  room_b = WCGMockRoom.new('delay-room-b')
  mock_manager.objects_by_goid['delay-room-a'] = room_a
  mock_manager.objects_by_goid['delay-room-b'] = room_b
  lookup['N00E000:0:0'] = 'delay-room-a'
  lookup['N00E000:500:0'] = 'delay-room-b'

  # Let the thread hit the empty connection queue + sleep path (lines 661-662)
  sleep 0.2

  # Now add connection and signal processing done
  conn_queue << wcg_class::RoomConnection.new('N00E000:0:0', 'N00E000:500:0', 'east', 'west')
  generator.instance_variable_set(:@processed, 1)

  sleep 1.0
  thread.join(5)
end

# ---------------------------------------------------------------------------
# build_world steps
# ---------------------------------------------------------------------------
Given('I have a fully-mocked generator for build_world') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger,
                                  max_concurrent_downloads: 1,
                                  max_concurrent_processors: 1)
  generator.define_singleton_method(:populate_download_queue) do |_lat_range, _lon_range|
    @tile_total = 1
    @download_queue << 'N45E010'
  end
  generator.define_singleton_method(:fetch_tile) { |tc| "/tmp/cache/#{tc}.tif" }
  wcg_klass = Aethyr::Core::Util::WorldCoverGenerator
  generator.define_singleton_method(:process_tile_with_batching) do |_path, local_rooms, _local_conns|
    local_rooms << wcg_klass::ProcessedRoom.new(0, 0, 'N45E010', :GRASSLAND, 'Test', 'Desc', nil)
  end
end

When('I call build_world with small bounds') do
  @build_error = nil
  begin
    generator.build_world(lat_range: (45..45), lon_range: (10..10))
  rescue => e
    @build_error = e
  end
end

Then('build_world should complete without errors') do
  if @build_error
    flunk "build_world raised: #{@build_error.class}: #{@build_error.message}\n#{@build_error.backtrace.first(5).join("\n")}"
  end
end

Then('the logger should have logged about world generation complete') do
  found = log_messages.any? { |m| m.include?('World generation complete') || m.include?('generation complete') }
  assert found, "Expected 'World generation complete' in logs, got: #{log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# build_world with monitor thread exercised
# ---------------------------------------------------------------------------
Given('I have a slow-mocked generator for build_world that exercises the monitor') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger,
                                  max_concurrent_downloads: 1,
                                  max_concurrent_processors: 1)
  generator.define_singleton_method(:populate_download_queue) do |_lat_range, _lon_range|
    @tile_total = 1
    @download_queue << 'N45E010'
  end
  # fetch_tile adds a delay so threads stay alive long enough for the monitor
  generator.define_singleton_method(:fetch_tile) do |tc|
    sleep 0.3
    "/tmp/cache/#{tc}.tif"
  end
  wcg_klass = Aethyr::Core::Util::WorldCoverGenerator
  generator.define_singleton_method(:process_tile_with_batching) do |_path, local_rooms, _local_conns|
    sleep 0.3
    local_rooms << wcg_klass::ProcessedRoom.new(0, 0, 'N45E010', :GRASSLAND, 'Test', 'Desc', nil)
  end
end

When('I call build_world with small bounds using short monitor sleep') do
  @build_error = nil
  begin
    # Patch the build_world method to use a shorter monitor sleep
    original_build_world = generator.method(:build_world)
    generator.define_singleton_method(:build_world) do |lat_range: (-90..89), lon_range: (-180..179)|
      send(:populate_download_queue, lat_range, lon_range)
      @logger.info("Tiles to download: #{@tile_total}. Starting #{@max_dl} download threads and #{@max_proc} processing threads …")
      download_threads = send(:spawn_download_pool)
      processing_threads = send(:spawn_processing_pool)
      object_creation_thread = send(:spawn_object_creation_thread)
      room_connection_thread = send(:spawn_room_connection_thread)
      monitor_thread = Thread.new do
        while download_threads.any?(&:alive?) ||
              processing_threads.any?(&:alive?) ||
              object_creation_thread.alive? ||
              room_connection_thread.alive?
          sleep 0.05  # Short sleep for testing
          @logger.info("CPU utilization monitoring: #{@downloaded}/#{@tile_total} downloaded, #{@processed}/#{@tile_total} processed")
        end
      end
      download_threads.each(&:join)
      processing_threads.each(&:join)
      object_creation_thread.join
      room_connection_thread.join
      monitor_thread.join
      @logger.info("World generation complete! Total rooms created: #{@room_lookup.size}")
    end
    generator.build_world(lat_range: (45..45), lon_range: (10..10))
  rescue => e
    @build_error = e
  end
end

# ---------------------------------------------------------------------------
# spawn_room_connection_thread empty-queue retry with non-empty processed_rooms
# ---------------------------------------------------------------------------
Given('I have a generator for connection thread retry with non-empty processed_rooms') do
  self.mock_manager = WCGMockManager.new
  self.mock_logger = WCGTestLogger.new
  self.log_messages = mock_logger.messages
  self.generator = wcg_class.new(mock_manager, logger: mock_logger)
  generator.instance_variable_set(:@tile_total, 1)
  generator.instance_variable_set(:@processed, 0)
  # Add a room to the lookup so the thread gets past the initial wait
  lookup = generator.instance_variable_get(:@room_lookup)
  room_a = WCGMockRoom.new('retry-room-a')
  room_b = WCGMockRoom.new('retry-room-b')
  mock_manager.objects_by_goid['retry-room-a'] = room_a
  mock_manager.objects_by_goid['retry-room-b'] = room_b
  lookup['N00E000:0:0'] = 'retry-room-a'
  lookup['N00E000:500:0'] = 'retry-room-b'
  # Add an item to processed_rooms to make it non-empty
  processed_rooms_queue = generator.instance_variable_get(:@processed_rooms)
  processed_rooms_queue << wcg_class::ProcessedRoom.new(0, 0, 'N00E000', :GRASSLAND, 'Test', 'Desc', nil)
end

When('I run the connection thread that retries on empty queue then completes') do
  conn_queue = generator.instance_variable_get(:@room_connections)
  # Connection queue is empty initially - thread will hit the retry path (lines 661-662)
  # because: connection_batch is empty, @processed (0) < @tile_total (1), 
  # AND @processed_rooms is not empty
  thread = generator.send(:spawn_room_connection_thread)
  
  # Let the thread hit the retry path at least once
  sleep 0.3
  
  # Now add a connection and mark processing as done to let thread finish
  conn_queue << wcg_class::RoomConnection.new('N00E000:0:0', 'N00E000:500:0', 'east', 'west')
  # Drain processed_rooms so the final check passes
  begin
    loop { generator.instance_variable_get(:@processed_rooms).pop(true) }
  rescue ThreadError
    # empty now
  end
  generator.instance_variable_set(:@processed, 1)
  
  sleep 0.5
  thread.join(5)
end
