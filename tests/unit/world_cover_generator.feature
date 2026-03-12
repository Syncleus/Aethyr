Feature: WorldCoverGenerator
  The WorldCoverGenerator orchestrates download, cache management, and
  incremental processing of ESA WorldCover raster tiles to build an
  in-game representation of planet Earth.

  # ---------------------------------------------------------------
  # Constants & configuration
  # ---------------------------------------------------------------
  Scenario: Constants are defined with expected values
    Given I require the WorldCoverGenerator library
    Then the RESOLUTION_METRES constant should equal 5000
    And the BUCKET_BASE_URL constant should include "world-terrain-data"
    And the YEAR constant should equal 2021
    And the VERSION constant should equal "v200"
    And the MAX_CONCURRENT_DL constant should equal 10
    And the MAX_TILES constant should equal 1
    And the BATCH_SIZE constant should equal 10
    And the MAX_CONCURRENT_PROC constant be at least 4
    And the CACHE_DIR constant should be a non-empty string

  Scenario: CODE_TO_TERRAIN maps all WorldCover codes
    Given I require the WorldCoverGenerator library
    Then CODE_TO_TERRAIN should map 10 to GRASSLAND
    And CODE_TO_TERRAIN should map 20 to GRASSLAND
    And CODE_TO_TERRAIN should map 30 to GRASSLAND
    And CODE_TO_TERRAIN should map 40 to GRASSLAND
    And CODE_TO_TERRAIN should map 50 to CITY
    And CODE_TO_TERRAIN should map 60 to GRASSLAND
    And CODE_TO_TERRAIN should map 70 to TUNDRA
    And CODE_TO_TERRAIN should map 80 to TUNDRA
    And CODE_TO_TERRAIN should map 90 to GRASSLAND
    And CODE_TO_TERRAIN should map 95 to GRASSLAND
    And CODE_TO_TERRAIN should map 100 to TUNDRA

  Scenario: NAME_TEMPLATES provides flavour names for each terrain type
    Given I require the WorldCoverGenerator library
    Then NAME_TEMPLATES should have entries for GRASSLAND, CITY, and TUNDRA
    And each NAME_TEMPLATES entry should be a non-empty array

  Scenario: DESCRIPTION_TEMPLATES provides flavour descriptions for each terrain type
    Given I require the WorldCoverGenerator library
    Then DESCRIPTION_TEMPLATES should have entries for GRASSLAND, CITY, and TUNDRA type descriptions
    And each DESCRIPTION_TEMPLATES entry should be a non-empty array of strings

  # ---------------------------------------------------------------
  # Internal data structures
  # ---------------------------------------------------------------
  Scenario: ProcessedRoom struct stores room data and computes position_key
    Given I require the WorldCoverGenerator library
    When I create a ProcessedRoom with x 100, y 200, tile_code "N45E010"
    Then the ProcessedRoom position_key should be "N45E010:100:200"

  Scenario: RoomConnection struct stores connection data
    Given I require the WorldCoverGenerator library
    When I create a RoomConnection with from_key "N45E010:0:0", to_key "N45E010:500:0", direction_from "east", direction_to "west"
    Then the RoomConnection should have correct from_key and to_key

  # ---------------------------------------------------------------
  # Construction
  # ---------------------------------------------------------------
  Scenario: Constructor accepts a valid manager and sets defaults
    Given I require the WorldCoverGenerator library
    And I have a mock manager
    When I create a WorldCoverGenerator with the mock manager
    Then the generator should be initialized without errors
    And the start_room_goid should be nil initially

  Scenario: Constructor raises ArgumentError for nil manager
    Given I require the WorldCoverGenerator library
    When I try to create a WorldCoverGenerator with nil manager
    Then an ArgumentError should be raised with message containing "Manager cannot be nil"

  Scenario: Constructor clamps resolution below 10 to 10
    Given I require the WorldCoverGenerator library
    And I have a mock manager
    When I create a WorldCoverGenerator with resolution 5
    Then the internal resolution should be 10

  Scenario: Constructor enforces minimum of 1 for download concurrency
    Given I require the WorldCoverGenerator library
    And I have a mock manager
    When I create a WorldCoverGenerator with max_concurrent_downloads 0
    Then the internal max_dl should be 1

  Scenario: Constructor enforces minimum of 1 for processing concurrency
    Given I require the WorldCoverGenerator library
    And I have a mock manager
    When I create a WorldCoverGenerator with max_concurrent_processors 0
    Then the internal max_proc should be 1

  # ---------------------------------------------------------------
  # decode_tile_origin
  # ---------------------------------------------------------------
  Scenario: Decode tile origin for northern eastern tile
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I decode tile origin for code "N45E010"
    Then the decoded latitude should be 45
    And the decoded longitude should be 10

  Scenario: Decode tile origin for southern western tile
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I decode tile origin for code "S30W120"
    Then the decoded latitude should be -30
    And the decoded longitude should be -120

  Scenario: Decode tile origin for southern eastern tile
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I decode tile origin for code "S00E000"
    Then the decoded latitude should be 0
    And the decoded longitude should be 0

  Scenario: Decode tile origin for northern western tile
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I decode tile origin for code "N90W180"
    Then the decoded latitude should be 90
    And the decoded longitude should be -180

  # ---------------------------------------------------------------
  # tile_origin
  # ---------------------------------------------------------------
  Scenario: tile_origin rounds down to nearest 3-degree boundary
    Given I require the WorldCoverGenerator library
    And I have a default generator
    Then tile_origin of 5 should be 3
    And tile_origin of -5 should be -6
    And tile_origin of 0 should be 0
    And tile_origin of 3 should be 3
    And tile_origin of -3 should be -3

  # ---------------------------------------------------------------
  # tile_code
  # ---------------------------------------------------------------
  Scenario: tile_code generates correct string for positive lat/lon
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I generate tile_code for lat 45 lon 10
    Then the tile_code should be "N45E009"

  Scenario: tile_code generates correct string for negative lat/lon
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I generate tile_code for lat -30 lon -120
    Then the tile_code should be "S30W120"

  Scenario: tile_code generates correct string for zero lat/lon
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I generate tile_code for lat 0 lon 0
    Then the tile_code should be "N00E000"

  # ---------------------------------------------------------------
  # fetch_bucket_listing
  # ---------------------------------------------------------------
  Scenario: fetch_bucket_listing without marker calls URI.open with correct params
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub URI.open at kernel level to return sample bucket XML
    When I call real fetch_bucket_listing with no marker
    Then the listing result should contain bucket XML data

  Scenario: fetch_bucket_listing with marker includes marker in URI params
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub URI.open at kernel level to return sample bucket XML
    When I call real fetch_bucket_listing with marker "some_marker_key"
    Then the listing result should contain bucket XML data

  # ---------------------------------------------------------------
  # populate_download_queue
  # ---------------------------------------------------------------
  Scenario: populate_download_queue discovers tiles within bounds
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub fetch_bucket_listing to return XML with tile "N45E010"
    When I populate the download queue for lat 40..50 and lon 5..15
    Then the download queue should have 1 tile
    And tile_total should be 1

  Scenario: populate_download_queue skips tiles outside bounds
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub fetch_bucket_listing to return XML with tile "N45E010"
    When I populate the download queue for lat 0..5 and lon 0..5
    Then the download queue should have 0 tile
    And tile_total should be 0

  Scenario: populate_download_queue respects tile limit
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub fetch_bucket_listing to return XML with multiple tiles
    When I populate the download queue for lat -90..90 and lon -180..180
    Then the download queue should have at most MAX_TILES tiles

  Scenario: populate_download_queue handles pagination
    Given I require the WorldCoverGenerator library
    And I have a default generator with unlimited tiles
    And I stub fetch_bucket_listing to return paginated XML
    When I populate the download queue for lat -90..90 and lon -180..180
    Then the download queue should have 2 tile

  Scenario: populate_download_queue logs with limit message
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub fetch_bucket_listing to return XML with tile "N45E010"
    When I populate the download queue for lat 40..50 and lon 5..15
    Then the logger should have logged a message containing "capped at"

  Scenario: populate_download_queue logs without limit message when no limit
    Given I require the WorldCoverGenerator library
    And I have a default generator with unlimited tiles
    And I stub fetch_bucket_listing to return XML with tile "N45E010"
    When I populate the download queue for lat 40..50 and lon 5..15
    Then the logger should have logged a message containing "matching requested bounds"

  # ---------------------------------------------------------------
  # fetch_tile
  # ---------------------------------------------------------------
  Scenario: fetch_tile returns cached path when file already exists on disk
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub File to report tile file exists and has size
    When I call the real fetch_tile with code "N45E010"
    Then the returned path should end with "N45E010_Map.tif"

  Scenario: fetch_tile downloads file when it does not exist on disk
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I stub File to report tile file does not exist and stub URI.open for download
    When I call the real fetch_tile with code "N45E010"
    Then the returned path should end with "N45E010_Map.tif"

  # ---------------------------------------------------------------
  # flush_local_batches
  # ---------------------------------------------------------------
  Scenario: flush_local_batches pushes rooms and connections to main queues
    Given I require the WorldCoverGenerator library
    And I have a default generator
    When I flush local batches with 3 rooms and 2 connections
    Then the processed_rooms queue should have 3 items
    And the room_connections queue should have 2 items

  # ---------------------------------------------------------------
  # process_tile_lockfree
  # ---------------------------------------------------------------
  Scenario: process_tile_lockfree processes a raster tile without shared state
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I have a mock GDAL dataset with width 1000 and height 1000
    When I call process_tile_lockfree with the mock dataset path
    Then the processed_rooms queue should have items
    And the room_connections queue should have items

  # ---------------------------------------------------------------
  # process_tile_with_batching
  # ---------------------------------------------------------------
  Scenario: process_tile_with_batching processes a raster tile with local batches
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I have a mock GDAL dataset with width 1000 and height 1000
    When I call process_tile_with_batching with the mock dataset path
    Then the local rooms batch should have items
    And the local connections batch should have items

  # ---------------------------------------------------------------
  # link_rooms
  # ---------------------------------------------------------------
  Scenario: link_rooms creates bidirectional exits between rooms
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I have two mock rooms with no existing exits
    When I call link_rooms between the two rooms
    Then link_rooms should return true
    And the manager should have created 2 exit objects

  Scenario: link_rooms returns false when room A is nil
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I have mock rooms where room A is nil
    When I call link_rooms with nil room A
    Then link_rooms should return false

  Scenario: link_rooms returns false when exits already exist
    Given I require the WorldCoverGenerator library
    And I have a default generator
    And I have two mock rooms with existing exits
    When I call link_rooms between rooms with existing exits
    Then link_rooms should return false

  Scenario: link_rooms returns false when create_object raises an error
    Given I require the WorldCoverGenerator library
    And I have a default generator with error-raising manager
    And I have two mock rooms with no existing exits for error test
    When I call link_rooms between the error test rooms
    Then link_rooms should return false

  # ---------------------------------------------------------------
  # create_missing_connections
  # ---------------------------------------------------------------
  Scenario: create_missing_connections scans rooms and creates missing exits
    Given I require the WorldCoverGenerator library
    And I have a default generator with rooms in lookup
    When I call create_missing_connections
    Then the logger should have logged about missing connections

  # ---------------------------------------------------------------
  # increment_download_counter and increment_process_counter
  # ---------------------------------------------------------------
  Scenario: increment_download_counter increments and logs
    Given I require the WorldCoverGenerator library
    And I have a default generator with tile_total set to 5
    When I call increment_download_counter
    Then the downloaded count should be 1

  Scenario: increment_process_counter increments and logs
    Given I require the WorldCoverGenerator library
    And I have a default generator with tile_total set to 5
    When I call increment_process_counter
    Then the processed count should be 1

  # ---------------------------------------------------------------
  # log_progress
  # ---------------------------------------------------------------
  Scenario: log_progress outputs formatted download and process percentages
    Given I require the WorldCoverGenerator library
    And I have a default generator with tile_total set to 5
    And the downloaded count is 2 and processed count is 1
    When I call log_progress
    Then the logger should have logged a message matching DL and PROC format

  # ---------------------------------------------------------------
  # spawn_object_creation_thread
  # ---------------------------------------------------------------
  Scenario: spawn_object_creation_thread creates rooms from queue data
    Given I require the WorldCoverGenerator library
    And I have a generator with mock manager for object creation
    When I enqueue processed rooms and run the object creation thread
    Then rooms should have been created via the manager
    And the room_lookup should have entries
    And start_room_goid should be set

  # ---------------------------------------------------------------
  # spawn_room_connection_thread
  # ---------------------------------------------------------------
  Scenario: spawn_room_connection_thread links rooms from connection queue
    Given I require the WorldCoverGenerator library
    And I have a generator ready for room connection
    When I enqueue room connections and run the connection thread
    Then connections should have been processed

  # ---------------------------------------------------------------
  # spawn_download_pool
  # ---------------------------------------------------------------
  Scenario: spawn_download_pool fetches tiles from the download queue
    Given I require the WorldCoverGenerator library
    And I have a generator with stubbed fetch_tile
    When I enqueue tile codes and run the download pool
    Then the process queue should have entries

  Scenario: spawn_download_pool handles download errors gracefully
    Given I require the WorldCoverGenerator library
    And I have a generator with failing fetch_tile
    When I enqueue tile codes and run the download pool with errors
    Then no exception should propagate from download threads

  # ---------------------------------------------------------------
  # spawn_processing_pool
  # ---------------------------------------------------------------
  Scenario: spawn_processing_pool processes tiles from the process queue
    Given I require the WorldCoverGenerator library
    And I have a generator with stubbed process_tile_with_batching
    When I enqueue tif paths and run the processing pool
    Then the processed count should increase

  # ---------------------------------------------------------------
  # spawn_processing_pool with batch flush
  # ---------------------------------------------------------------
  Scenario: spawn_processing_pool flushes batches when large enough
    Given I require the WorldCoverGenerator library
    And I have a generator producing large batches for processing pool
    When I enqueue tif paths and run the processing pool with large batches
    Then the processed_rooms queue should have items after flush

  Scenario: spawn_processing_pool retries when queue is temporarily empty
    Given I require the WorldCoverGenerator library
    And I have a generator with delayed download for processing pool
    When I start the processing pool then add work after a delay
    Then the processed count should increase

  # ---------------------------------------------------------------
  # spawn_object_creation_thread with periodic logging and retry
  # ---------------------------------------------------------------
  Scenario: spawn_object_creation_thread logs periodically at room count multiples
    Given I require the WorldCoverGenerator library
    And I have a generator with mock manager for object creation
    When I enqueue exactly 100 processed rooms and run the object creation thread
    Then the logger should have logged a message containing "rooms so far"

  Scenario: spawn_object_creation_thread retries when room queue is temporarily empty
    Given I require the WorldCoverGenerator library
    And I have a generator with mock manager for delayed object creation
    When I start the object creation thread then add rooms after a delay
    Then rooms should have been created via the manager

  # ---------------------------------------------------------------
  # spawn_room_connection_thread with periodic logging and retry
  # ---------------------------------------------------------------
  Scenario: spawn_room_connection_thread logs at connection count multiples
    Given I require the WorldCoverGenerator library
    And I have a generator ready for room connection with many rooms
    When I enqueue many room connections and run the connection thread
    Then the logger should have logged a message containing "exits"

  Scenario: spawn_room_connection_thread waits for rooms then retries on empty queue
    Given I require the WorldCoverGenerator library
    And I have a generator for delayed room connection
    When I start the connection thread then add rooms and connections after a delay
    Then connections should have been processed

  # ---------------------------------------------------------------
  # build_world (integration of all stages)
  # ---------------------------------------------------------------
  Scenario: build_world runs the full pipeline end to end
    Given I require the WorldCoverGenerator library
    And I have a fully-mocked generator for build_world
    When I call build_world with small bounds
    Then build_world should complete without errors
    And the logger should have logged about world generation complete
